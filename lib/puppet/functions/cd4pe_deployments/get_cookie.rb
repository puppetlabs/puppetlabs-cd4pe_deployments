require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Get a CD4PE cookie to use APIs that don't support token auth
Puppet::Functions.create_function(:'cd4pe_deployments::get_cookie') do
  # @param login_user
  #   The CD4PE user login (email address)
  # @param login_pwd
  #   The CD4PE user password
  # @example Get a cookie
  #   $cookie = get_cookie('user@domain.com', 'P@ssw0rd')
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [String] the cookie value
  #   * error [Hash] contains error information if any
  #
  dispatch :get_cookie do
    required_param 'String', :login_user
    required_param 'String', :login_pwd
  end

  def get_cookie(login_user, login_pwd)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.get_cookie(login_user, login_pwd)
    case response
    when Net::HTTPSuccess
      PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(response['Set-Cookie'])
    when Net::HTTPClientError
      response_body = JSON.parse(response.body, symbolize_names: false)
      PuppetX::Puppetlabs::CD4PEFunctionResult.create_error_result(response_body)
    when Net::HTTPServerError
      raise Puppet::Error "Unknown HTTP Error with code: #{response.code} and body #{response.body}"
    end
  end
end
