module Spree
  class Gateway::Instamojo < Gateway

    preference :api_key, :string
    preference :auth_token, :string
    preference :salt, :string
    preference :site_url, :string

    def supports?(source)
      true
    end

    def provider_class
      self.class
    end

    def provider
      self
    end

    def auto_capture?
      true
    end

    def method_type
      "instamojo"
    end

    def purchase(amount, source, gateway_options={})
      ActiveMerchant::Billing::Response.new(true, "paytm success")
    end
    def redirect_url
      preferred_site_url+"/instamojo/confirm"
    end

    def get_instamojo_url
      if preferred_test_mode
        "https://test.instamojo.com/api/1.1/payment-requests/"
      else
        "https://www.instamojo.com/api/1.1/payment-requests/"
      end
    end

  end
end