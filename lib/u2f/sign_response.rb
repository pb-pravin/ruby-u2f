module U2F
  class SignResponse
    attr_accessor :client_data, :client_data_json, :key_handle, :signature_data

    def self.load_from_json(json)
      data = ::JSON.parse(json)
      instance = new
      instance.client_data_json =
        ::U2F.urlsafe_decode64(data['clientData'])
      instance.client_data =
        ClientData.load_from_json(instance.client_data_json)
      instance.key_handle = data['keyHandle']
      instance.signature_data =
        ::U2F.urlsafe_decode64(data['signatureData'])
      instance
    end

    ##
    # Counter value that the U2F token increments every time it performs an
    # authentication operation
    def counter
      signature_data[1..4].unpack('N').first
    end

    ##
    # signature is to be verified using the public key obtained during
    # registration.
    def signature
      signature_data.byteslice(5..-1)
    end

    ##
    # If user presence was verified
    def user_present?
      signature_data[0].unpack('C').first == 1
    end

    ##
    # Verifies the response against an app id and the public key of the
    # registered device
    def verify(app_id, public_key_pem)
      data = [
        Digest::SHA256.digest(app_id),
        signature_data.byteslice(0, 5),
        Digest::SHA256.digest(client_data_json)
      ].join

      public_key = OpenSSL::PKey.read(public_key_pem)
      public_key.verify(OpenSSL::Digest::SHA256.new, signature, data)
    end
  end
end
