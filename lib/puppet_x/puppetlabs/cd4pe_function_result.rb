module PuppetX::Puppetlabs
  # A static class to create a standard result format for custom deploy functions
  class CD4PEFunctionResult
    UNKNOWN_ERROR_CODE = 'UnknownError'.freeze
    ENCOUNTERED_EXCEPTION_CODE = 'EncounteredException'.freeze

    def self.create_result_hash(result)
      { result: result }
    end

    def self.create_error_hash(message, code)
      if message && code
        error_body = {
          message: message,
          code: code,
        }
      end

      { error: error_body }
    end

    def self.create_result(result, error_message = nil, error_code = nil)
      create_result_hash(result).merge(create_error_hash(error_message, error_code))
    end

    def self.create_error_result(response)
      create_result(
        nil,
        response[:error][:message],
        response[:error][:code],
      )
    end

    def self.create_exception_result(exception)
      PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(
        nil,
        "Encountered exception: #{exception.message}",
        ENCOUNTERED_EXCEPTION_CODE,
      )
    end
  end
end
