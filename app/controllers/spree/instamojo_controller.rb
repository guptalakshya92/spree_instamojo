module Spree
  class InstamojoController < StoreController
    protect_from_forgery only: :index

    def index
      payment_method = Spree::PaymentMethod.find(params[:payment_method_id])
      order = current_order
      @param_list = Hash.new
        if(address = current_order.bill_address || current_order.ship_address)
          phone = address.phone
        end
        @param_list[:buyer_name] = address.firstname
        @param_list[:purpose] = order.number
        @param_list[:amount] = order.total.to_s
        @param_list[:email] = order.email
        @param_list[:phone] = phone
        @param_list[:redirect_url] = payment_method.redirect_url
        @param_list[:allow_repeated_payments] = false
        @param_list[:send_email] = false
        @param_list[:send_sms] = false
        request = Typhoeus.post(payment_method.get_instamojo_url,
                    body: @param_list,
                    headers: {'X-Api-Key' => payment_method.preferred_api_key,
                              'X-Auth-Token'=> payment_method.preferred_auth_token})
      response = JSON.parse(request.response_body)
      if response.present? && response["success"] && response["payment_request"]["longurl"].present?
        @instamj_txn_url = response["payment_request"]["longurl"]+"?embed=form"
      else
        flash[:error] = "Payment failed"
        redirect_to checkout_state_path(order.state) and return
      end
    end

    def confirm
      @payment_method = Spree::PaymentMethod.find_by(type: Spree::Gateway::Instamojo.to_s)
      payment_request_id = params[:payment_request_id]
      @order = current_order
      if payment_request_id.present?
        payment_details_request = Typhoeus.get("https://test.instamojo.com/api/1.1/payment-requests/"+payment_request_id+"/",
                                        headers: {'X-Api-Key' => @payment_method.preferred_api_key,
                                                  'X-Auth-Token'=> @payment_method.preferred_auth_token})
        payment_details_response = JSON.parse(payment_details_request.response_body)
        @order = @order || Spree::Order.find_by(number: payment_details_response["payment_request"]["purpose"])
        payment = payment_details_response["payment_request"]["payments"].select { |payment| payment["status"] === 'Credit' && payment["amount"].to_f === @order.total.to_f}.last
        if payment.present? && payment["status"] === "Credit"
          success_payment payment_request_id, payment
        else
          failed_payment payment_request_id
        end
      else
        @error = true
        @message = "There was an error processing your payment"
        @redirect_path = checkout_state_path(@order.state)
      end

    end

    def failed_payment payment_request_id
      payment_request_id = payment_request_id
      res_code = "301"
      update_payment(payment_request_id, nil, nil, 'Failed', res_code)
      @payment.state = "failed"
      @payment.save
      @order.update_attributes(payment_state: "failed")
      @error = true
      @message = "There was an error processing your payment"
      @redirect_path = checkout_state_path(@order.state)
    end

    def success_payment payment_request_id , payment
      payment_request_id = payment_request_id
      payment_id = payment["payment_id"]
      status = payment["status"]
      amount = payment["amount"]
      res_code = "201"
      update_payment(payment_request_id, payment_id, amount, status, res_code)
      @order.next!
      @message = Spree.t(:order_processed_successfully)
      @current_order = nil
      flash.notice = Spree.t(:order_processed_successfully)
      flash['order_completed'] = true
      @error = false
      @redirect_path = order_path(@order)
    end


    private

    def update_payment payment_request_id , payment_id, amount, status, res_code
      @payment = @order.payments.create!(
          payment_method: @payment_method,
          source: Spree::PaymentCheckout.create(
              payment_request_id: payment_request_id,
              payment_id: payment_id,
              order_id: @order.id,
              status: status,
              amount: amount
          ),
          amount: @order.total,
          response_code: res_code
      )

    end
  end

end