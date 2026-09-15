require 'puppet_x/puppetlabs'
require 'json'

# A static class to create a standard result format for custom deploy functions
class PuppetX::Puppetlabs::CD4PEFunctionResult
  ENCOUNTERED_EXCEPTION_CODE = 'EncounteredException'.freeze

  def self.create_result_hash(result)
    { 'result' => result }
  end

  def self.create_error_hash(message, code)
    if message && code
      error_body = {
        'message' => message,
        'code' => code,
      }
    end

    { 'error' => error_body }
  end

  def self.create_result(result, error_message = nil, error_code = nil)
    create_result_hash(result).merge(create_error_hash(error_message, error_code))
  end

  def self.create_error_result(response)
    create_result(
      nil,
      response['error']['message'],
      response['error']['code'],
    )
  end

  # Builds an error result from a V1 API error response.
  #
  # V1 error bodies are flat -- message, traceId, uriPath, errors -- with no 'error' wrapper
  # key, so create_error_result cannot read them. Prefers the body's legacyCode, the semantic
  # code the AJAX endpoints used to set and customer deployment policies match on, and falls
  # back to the HTTP status for the V1 error paths that do not carry one.
  def self.create_v1_error_result(response)
    body = JSON.parse(response.body, symbolize_names: false)
    create_result(
      nil,
      body['message'],
      body['legacyCode'] || response.code,
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
