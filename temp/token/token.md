Introduction

The Deutsche Bank API Program allows access to customer data or customer related functionalities. As we value the privacy of our customers, every request to the api requires authorization. Using industry standards like OAuth2.0 and OpenID Connect, we give our customers the means to control which application can access what data.

If you are familiar with the OAuth2.0 standard, you might want to jump right into the specific documentation of what we offer under the standard and how to use it.

The OAuth2.0 standard makes it possible for a user of an app to grant limited access to the app to her data. This is done in such a way that she does not need to share any credentials related to Deutsche Bank with the app. Limited in this context refers to both a time frame and which kind of data can be accessed.

You might wonder if it’s also possible to use our apis for machine-to-machine communication, that is without a user context. We do offer certain apis without an authorisation by a user, also building on the foundations of the OAuth2.0 standard.

If you are new to the OAuth2.0 standard, it can seem overly complicated. Also, the terms used can be confusing. We’ll try to shed some light on them with the specific sections.


Supported grant types

The apis offered by the Deutsche Bank API Program usually require an authorisation. We build on the OAuth2.0 standard for this. However, we don’t support every possibility covered by the standard. Here we show what you can use. We currently support the following OAuth 2.0 authorisation flows:
Authorization Code Grant

The authorisation code grant flow first gets a code and then exchanges it for an access token. Since the exchange uses your Client Secret Key, you should make that request on the server-side to keep the integrity of the key. If you are developing a Web, Android or iOS app backed by a server, you should use the authorisation code grant flow. As part of your go live request, we reserve the right to prescribe the use of PKCE, depending on your application topology.
Authorization Code Grant with PKCE

The authorisation code grant with PKCE OAuth 2.0 flow to allow the authorisation server to verify that it's communicating with your app only. If you are developing an app which requires a user interaction, you should use the authorisation code grant flow with PKCE.
Client Credentials Grant

The client credentials grant flow is only carried out for clients that are classified as confidential by Deutsche Bank. The access tokens that are issued are short-lived (currently 600 seconds = 10 minutes). If you are developing an application that is classified as confidential by Deutsche Bank and does not utilise user contexts (machine-to-machine application), use the client credentials flow.
Refresh Token Grant

The refresh token grant flow is only carried out if you have used the authorisation code grant before. Access tokens expire. However, the authorisation grant responds with a refresh token that enables the client to refresh the access token. The refresh tokens are long-lived (currently 180 days). If you develop an application that uses the authorisation grant flow, you will be able to request a refresh token.
Not supported grant types

The OAuth2.0 standard covers a lot of usecases. However, we don’t support every possibility covered by the standard. Here is what you can't use:
Implicit grant

The Implicit grant is a simplified flow for both native apps and browser-based Javascript apps. It returns an access token in a HTTP redirect without an additional authentication code exchange. This leads to a number of security issues which is the reason why we do not support it. For further information please refer to this page.

If you are developing a public client or a native app without a server backend, consider using the Authorisation code grant with PKCE.
Password grant

The Password grant type is a legacy way to exchange user credentials for an access token. To do so, the client application has to collect the user's id and password and send it to the authorization server. This leads to a number of security issues which is the reason why we do not support it.


Authorisation code grant

We strongly recommend that all clients use the PKCE extension with this flow to prevent CSRF and authorization code injection attacks.

The Authorisation Code grant type is used by confidential clients to exchange an authorisation code for an access token. This grant type requires a user interaction. After the user returns to your app via the redirect URL, your app will get the authorisation code from the URL and use it to request an access token.

Access tokens are used by your application to access our dbAPI endpoints. They are short-lived and expire after 600 seconds = 10 minutes. An ID token will be returned in the authorisation response by default. If your app has permissions to use refresh tokens, the authorisation response returns a refresh token too.
1. Send a request to the Deutsche Bank API Program authorisation service

The authorisation process starts with your application sending a request to the Deutsche Bank API Program authorisation service. The reason to trigger this request can vary: it may be a step in the initialisation of your application or a response to some user action, e.g., a button click. The request is sent to the authorisation URL.

The request includes the following parameters in the query string:
URL query string parameter 	Description
client_id 	Required. The client identifier provided to you by dbAPI after you register your application in the Developer Portal. For more info see RFC6749:Section 2.2
response_type 	Required. Value MUST be set to 'code'.
redirect_uri 	Optional. Required, if you specify more than one redirect URI for your application. The URI to redirect to after the user grants/denies permission. This URI needs to have been entered in the redirect URI that you specified when you registered your application. The value of this query parameter must exactly match one of the values you entered when you registered your application, including upper/lower case, terminating slashes, etc. For more info see RFC6749:Section 3.1.2
scope 	Optional. The scope of the access request as described by RFC6749:Section 3.3. The scope parameter intends to select a sub-set of scopes that your application has but not more, to be presented to the user and ask permission for. If you don't provide the scope parameter in this request, all scopes assigned to your application are presented to the user and ask permission for.
state 	Recommended. An opaque value used by the client to maintain state between the request and callback. The authorization server includes this value when redirecting the user-agent back to the client. The parameter SHOULD be used for preventing cross-site request forgery as described in RFC6749:Section 10.12.
acr_values 	Optional. Denotes the Authentication Context Class Reference (ACR) and can be used to force the usage of a second factor during authentication of the customer by setting the value to 'urn:dbapi:psd2:sca'. For more information on this so-called Strong Customer Authentication, see Section 3 below.

Let's take a look at an example:

GET https://simulator-api.db.com/gw/oidc/authorize?response_type=code&redirect_uri=<your_redirect_uri>&client_id=<your_client_id>&state=<your_state>

2. Redirect to login page

After the first request above, the user will be redirected to the login page of our authorisation service.
3. The user is asked to log in and grant access to the presented scopes

The authorisation service checks whether the user has authorised the client application to access the user's data. The user is then prompted to login by providing a valid FKN and PIN. The login step can be skipped if a successful login has already been performed and the user session has not been expired. The user is then asked to select the scope of access which they want to grant to the client application. This step can be skipped if the user already gave their consent to the client application.

Note: The user does not enter the credentials (FKN and PIN) in the client application, but rather in a Deutsche Bank API Program-prompted screen itself. As a result, no trust boundaries are violated. You can get further information about the FKN and PIN in our FAQ.

Depending on the information your app wants to access, a second factor during the authentication is mandated by the PSD2 regulations, also known as Strong Customer Authentication (SCA). PSD2 regulations mandate the use of SCA when accessing:

    cash account transaction data (affected scopes: read_transactions, categorized_transactions)
    certain cash account details, such as the account balance (affected scope: read_accounts)

For most requests it is sufficient that the SCA is performed every 180 days. This is usually aligned with the renewal of your refresh token, so interaction from the user is kept to a minimum. A client does not need to take extra steps in addition to those mandated by the OAuth 2 standard on Authorization Code Grant (with or without PKCE). When a client starts the authentication of a customer via the call to the authorize endpoint, we will guide the customer through a second factor flow after the login and consent and before redirecting back to the redirect URI of the client, if we deem SCA necessary.

Access tokens that are directly issued through an authorization code grant with SCA, carry a Authentication Context Class Reference (ACR) which denotes them as having SCA quality. A client can check the ACR claim under the key 'acr' as part of the id token (if requested). An access token issued with SCA would carry a value of "urn:dbapi:psd2:sca" here. Access tokens that were derived from a refresh token do not have that SCA quality.

Please note, that if your app wants to access transaction data older than 180 days, the access token used for the call must have SCA quality and thus must be derived directly from a SCA. In this case, the client can enforce the SCA by providing an additional query parameter to the authorize call to obtain the token, also see Section 1 above.
4. Redirect the user to your application

After the user grants (or denies) access, the Deutsche Bank API Program authorisation service redirects the user to the registered and optionally requested redirect URI. If the user has granted access, the final URI will contain the following data encoded as a query string:
URL query string parameter 	Description
code 	Required. An authorisation code that can be exchanged for an access token.
state 	Required. If the 'state' parameter was present in the client authorisation request, the exact value is returned.

Let's take a look at an example:

GET <your_redirect_uri>?code=<your_code>&state=<your_state>

5. Request access token

After the authorisation code has been received, the application backend needs to exchange this code for an access token. This is accomplished by making a POST request to the token endpoint.

The header of this POST request must contain the following parameter:
Header parameter 	Description
Authorization 	Required. Base64 encoded string that contains the Client ID and Client Secret Key, prefixed by the HTTP authorisation keyword: Authorization: Basic <your_client_id>:<your_client_secret>

You need to send the following parameters using the 'application/x-www-form-urlencoded' format in the HTTP request entity-body:
Body parameter 	Description
grant_type 	Required. Value MUST be set to 'authorization_code'.
code 	Required. The authorisation code returned from the initial request to the authorize endpoint.
redirect_uri 	Required, if the 'redirect_uri' parameter was included in the authorization request as described in RFC6749:Section 4.1.1, and their values MUST be identical. This parameter is used for validation only (there is no actual redirection).

Let's take a look at an example:

POST https://simulator-api.db.com/gw/oidc/token Authorization: Basic UzZ3...Pc25IUzZ3 Content-Type: application/x-www-form-urlencoded grant_type=authorization_code&code=aeLiAN&redirect_uri=http://localhost:8080/oauth2-client-webapp/redirect

6. Deliver the access token to your application backend

A successful response from the Deutsche Bank authorisation service has the status code 200 OK in the response header. The following JSON data is included in the response body:
Key 	Value type 	Description
access_token 	string 	An access token to be used in subsequent calls to access Deutsche Bank API Program services.
token_type 	string 	The token type is always 'Bearer'.
refresh_token 	string 	Optional. A special token that is used to get a new access token without user interaction. Gets returned with this authorisation response, if your client has the permissions to use refresh tokens.
expires_in 	string 	The lifetime of the access token in seconds.
scope 	string 	Optional, if identical to the scope requested by your client; otherwise, required. Get a list of available scopes by grant type here.
id_token 	string 	Optional. The ID token is a JWT security token that includes claims regarding the authentication of the user by the authorization server which can be used in your application.

Let's look at an example here:

{
  "access_token": "eyJraWQiOiJyc2ExIiwiYWxnIjoiUlMy...",
  "token_type": "Bearer",
  "expires_in": 599,
  "id_token": "eyJraWQiOiJpZHBfc2lnbmVyX2RiXzIwMjIiL..."
}

If your app has the permissions to use refresh tokens, the authorisation response looks like:

{
  "access_token": "eyJraWQiOiJyc2ExIiwiYWxnIjoiUlMy...",
  "token_type": "Bearer",
  "expires_in": 3599,
  "id_token": "eyJraWQiOiJpZHBfc2lnbmVyX2RiXzIwMjIiL...",
  "refresh_token": "eyJhbGciOiJub25lIn0.eyJleHAiOjE2...",
  "scope": "offline_access read_accounts openid"
}

7. Parse and validate the access token

Your application should parse and validate the access token before executing requests to the Deutsche Bank API Program endpoints to make sure the access token isn’t compromised and the signature is authentic. You can parse and validate JWTs e.g. by:

    Using any existing middleware for your web framework
    Choosing a third-party library from JWT.io
    Manually implementing the checks described in RFC 7519.

We strongly recommend that you use middleware or one of the existing third-party libraries to parse and validate JWTs instead of manually implementing the checks to avoid potential security vulnerabilities.
8. Use the access token to execute requests to the Deutsche Bank API Program endpoints

After parsing and validating the access token, you use the access token to execute requests to get information about cash accounts for example. To access our endpoints, you have to provide the HTTP header "Authorization: Bearer <access-token>" during the endpoint calls. As a response you should get information of the customer in JSON format.
Java tutorial
Checkout our Java tutorial

Take a view and download our Java tutorial which is a step by step guide explaining what you have to do. It shows how to get access to the simulation environment with the usage of the Authorisation code grant type with PKCE.


Authorisation code grant with PKCE

The Authorisation Code grant type with Proof Key for Code Exchange (PKCE) is used by confidential and public clients to exchange an authorization code for an access token.

This grant type requires a user interaction. After the user returns to your app via the redirect URL, your app will get the authorisation code from the URL and use it to request an access token.

Access tokens are used by your application to access our dbAPI endpoints. They are short-lived and expire after 600 seconds = 10 minutes. An ID token will be returned in the authorisation response by default. If your app has permissions to use refresh tokens, the authorisation response returns a refresh token too. However, to get refresh tokens, your client has to be classified as a confidential client, that means that your client gets a client secret.

PKCE is an extension of the Authorization Code grant type. It's not a replacement for a client secret, and PKCE is recommended even if your app is using a client secret.

Examples for apps which should use the Authorisation Code flow with PKCE are:

    Server based Web Applications
    Single Page/JavaScript Application
    Native, Mobile or Desktop applications

Make sure you have:

    App Client ID
    For confidential clients only, an App Client Secret Key
    An appropriate redirect URI registered in the Developer Portal

Refer to our Getting Started Guide to understand how to get this data. The authorisation code grant flow is illustrated by the following diagram.

1. Create a code verifier and a code challenge

Create a high-entropy cryptographic random string between 43 and 128 characters long using the unreserved characters [A-Z] / [a-z] / [0-9] / "-" / "." / "_" / "~". This is your code verifier. From your code verifier you've to create a code challenge which has to be SHA-256, base64 URL encoded String. Both are send to the authorisation server within different steps of the OAuth 2.0 flow to allow the authorisation server to verify that it's communicating with your app only. You can find some Java examples on how to create a code verifier and a code challenge in our tutorial in step 0.1 and 0.2. More information can also be found in RFC 7636.
2. Send a request to the Deutsche Bank API Program authorisation service

The authorisation process starts with your application sending a request to the Deutsche Bank API Program authorisation service. The reason to trigger this request can vary: it may be a step in the initialisation of your application or a response to some user action, e.g., a button click. The request is sent to the authorisation URL.

The request includes the following parameters in the query string:
URL query string parameter 	Description
client_id 	Required. The client identifier provided to you by dbAPI after you register your application in the Developer Portal. For more info see RFC6749:Section 2.2
response_type 	Required. Value MUST be set to 'code'.
redirect_uri 	Optional. Required, if you specify more than one redirect URI for your application. The URI to redirect to after the user grants/denies permission. This URI needs to have been entered in the redirect URI that you specified when you registered your application. The value of this query parameter must exactly match one of the values you entered when you registered your application, including upper/lower case, terminating slashes, etc. For more info see RFC6749:Section 3.1.2
code_challenge_method 	Required. Must be 'S256'.
code_challenge 	Required. Your generated PKCE code challenge. Must be BASE64URL-ENCODE(SHA256(ASCII(your_code_verifier))) String. For more info see RFC7636:Section 4.1
scope 	Optional. The scope of the access request as described by RFC6749:Section 3.3. The scope parameter intends to select a sub-set of scopes that your application has but not more, to be presented to the user and ask permission for. If you don't provide the scope parameter in this request, all scopes assigned to your application are presented to the user and ask permission for.
state 	Recommended. An opaque value used by the client to maintain state between the request and callback. The authorization server includes this value when redirecting the user-agent back to the client. The parameter SHOULD be used for preventing cross-site request forgery as described in RFC6749:Section 10.12.
acr_values 	Optional. Denotes the Authentication Context Class Reference (ACR) and can be used to force the usage of a second factor during authentication of the customer by setting the value to 'urn:dbapi:psd2:sca'. For more information on this so-called Strong Customer Authentication, see Section 3 below.

Let's take a look at an example:

GET https://simulator-api.db.com/gw/oidc/authorize?response_type=code&redirect_uri=<your_redirect_uri>&client_id=<your_client_id>code_challenge_method=S256&code_challenge=<your_generated_code_challenge>&state=<your_state>

3. Redirect to login page

After the first request above, the user will be redirected to the login page of our authorisation service.
4. The user is asked to log in and grant access to the presented scopes

The authorisation service checks whether the user has authorised the client application to access the user's data. The user is then prompted to login by providing a valid FKN and PIN. The login step can be skipped if a successful login has already been performed and the user session has not been expired. The user is then asked to select the scope of access which they want to grant to the client application. This step can be skipped if the user already gave their consent to the client application.

Note: The user does not enter the credentials (FKN and PIN) in the client application, but rather in a Deutsche Bank API Program-prompted screen itself. As a result, no trust boundaries are violated. You can get further information about the FKN and PIN in our FAQ.

Depending on the information your app wants to access, a second factor during the authentication is mandated by the PSD2 regulations, also known as Strong Customer Authentication (SCA). PSD2 regulations mandate the use of SCA when accessing:

    cash account transaction data (affected scopes: read_transactions, categorized_transactions)
    certain cash account details, such as the account balance (affected scope: read_accounts)

For most requests it is sufficient that the SCA is performed every 180 days. This is usually aligned with the renewal of your refresh token, so interaction from the user is kept to a minimum. A client does not need to take extra steps in addition to those mandated by the OAuth 2 standard on Authorization Code Grant (with or without PKCE). When a client starts the authentication of a customer via the call to the authorize endpoint, we will guide the customer through a second factor flow after the login and consent and before redirecting back to the redirect URI of the client, if we deem SCA necessary.

Access tokens that are directly issued through an authorization code grant with SCA, carry a Authentication Context Class Reference (ACR) which denotes them as having SCA quality. A client can check the ACR claim under the key 'acr' as part of the id token (if requested). An access token issued with SCA would carry a value of "urn:dbapi:psd2:sca" here. Access tokens that were derived from a refresh token do not have that SCA quality.

Please note, that if your app wants to access transaction data older than 180 days, the access token used for the call must have SCA quality and thus must be derived directly from a SCA. In this case, the client can enforce the SCA by providing an additional query parameter to the authorize call to obtain the token, also see Section 1 above.
5. Redirect the user to your application

After the user grants (or denies) access, the Deutsche Bank API Program authorisation service redirects the user to the registered and optionally requested redirect URI. If the user has granted access, the final URI will contain the following data encoded as a query string:
URL query string parameter 	Description
code 	Required. An authorisation code that can be exchanged for an access token.
state 	Required. If the 'state' parameter was present in the client authorisation request, the exact value is returned.

Let's take a look at an example:

GET <your_redirect_uri>?code=<your_code>&state=<your_state>

6. Request access token

After the authorisation code has been received, your application needs to exchange this code for an access token. This is accomplished by making a POST request to the token endpoint. In contrast to the authorisation request the request to the token endpoint must be initiated by your application directly using HTTPS and therefore neither the request nor the response can be overheard by another application on the same device. Upon receipt of this request, the authorisation server verifies it by calculating the code challenge from the received code verifier and comparing it with the previously associated code challenge, after first transforming it according to the code challenge method S256.

The header of this POST request is optional. If the client you use is a public client, this header must not be used. If the client you use is a confidential client it must contain the following parameter:
Header parameter 	Description
Authorization 	Optional. Depends if your client has a client secret (confidential client) or not (public client). Base64 encoded string that contains the Client ID and Client Secret Key, prefixed by the HTTP authorisation keyword: Authorization: Basic <your_client_id>:<your_client_secret>

You need to send the following parameters using the 'application/x-www-form-urlencoded' format in the HTTP request entity-body:
Body parameter 	Description
grant_type 	Required. Value MUST be set to 'authorization_code'.
code 	Required. The authorisation code returned from the initial request to the authorize endpoint.
redirect_uri 	Required, if the 'redirect_uri' parameter was included in the authorization request as described in RFC6749:Section 4.1.1, and their values MUST be identical. This parameter is used for validation only (there is no actual redirection).
code_verifier 	Required. Your generated code verifier from step one. Has to be a high-entropy cryptographic random string with a minimum length of 43 characters and a maximum length of 128 characters.

Let's take a look at an example:

POST https://simulator-api.db.com/gw/oidc/token Content-Type: application/x-www-form-urlencoded grant_type=authorization_code&code=aeLiAN&redirect_uri=http://localhost:8080/oauth2-client-webapp/redirect&code_verifier=<your_generated_code_verifier>

7. Deliver the access token to your application

A successful response from the Deutsche Bank authorisation service has the status code 200 OK in the response header. The following JSON data is included in the response body:
Key 	Value type 	Description
access_token 	string 	An access token to be used in subsequent calls to access Deutsche Bank API Program services.
token_type 	string 	The token type is always 'Bearer'.
refresh_token 	string 	Optional. A special token that is used to get a new access token without user interaction. Gets returned with this authorisation response, if your client has the permissions to use refresh tokens.
expires_in 	string 	The lifetime of the access token in seconds.
scope 	string 	Optional, if identical to the scope requested by your client; otherwise, required. Get a list of available scopes by grant type here.
id_token 	string 	Optional. The ID token is a JWT security token that includes claims regarding the authentication of the user by the authorization server which can be used in your application.

Let's look at an example here:

{
  "access_token": "eyJraWQiOiJyc2ExIiwiYWxnIjoiUlMy...",
  "token_type": "Bearer",
  "expires_in": 599,
  "id_token": "eyJraWQiOiJpZHBfc2lnbmVyX2RiXzIwMjIiL..."
}

If your app has the permissions to use refresh tokens, the authorisation response looks like:

{
  "access_token": "eyJraWQiOiJyc2ExIiwiYWxnIjoiUlMy...",
  "token_type": "Bearer",
  "expires_in": 3599,
  "id_token": "eyJraWQiOiJpZHBfc2lnbmVyX2RiXzIwMjIiL...",
  "refresh_token": "eyJhbGciOiJub25lIn0.eyJleHAiOjE2...",
  "scope": "offline_access read_accounts openid"
}

8. Parse and validate the access token

Your application should parse and validate the access token before executing requests to the Deutsche Bank API Program endpoints to make sure the access token isn’t compromised and the signature is authentic. You can parse and validate JWTs e.g. by:

    Using any existing middleware for your web framework
    Choosing a third-party library from JWT.io
    Manually implementing the checks described in RFC 7519.

We strongly recommend that you use middleware or one of the existing third-party libraries to parse and validate JWTs instead of manually implementing the checks to avoid potential security vulnerabilities.
9. Use the access token to execute requests to the Deutsche Bank API Program endpoints

After parsing and validating the access token, you use the access token to execute requests to get information about cash accounts for example. To access our endpoints, you have to provide the HTTP header "Authorization: Bearer <access-token>" during the endpoint calls. As a response you should get information of the customer in JSON format.
Java tutorial
Checkout our Java tutorial

Take a view and download our Java tutorial which is a step by step guide explaining what you have to do. It shows how to get access to the simulation environment with the usage of the Authorisation code grant type with PKCE.


Client credentials grant

The Client Credentials grant type is used by clients without any user context involved to obtain an access token. Apps which use the client credential grant can't use refresh tokens. To increase security, we rely on using JSON Web Tokens (JWT) for authentication instead of using a client secret.

The JWTs are signed with a JSON Web Key (JWK). In general, a JWK represents a cryptographic key. However, on the apis usable with the client credentials flow, we restrict the usage to asymmetric key pairs. Asymmetric key pairs consist of a private key and a public key. The private key is used to sign the JWT. By doing so the signer proves that they (and only they) are in possession of the private key. The public key is used to verify the signature. It is accessible to everyone, so everyone is able to verify the signature. By doing so, the verifier can make sure that the JWT was indeed signed by the owner of the private key.

The private part is yours - make sure to keep it confidential. The public part needs to be stored with us as part of a JSON Web Key Set - JWKS according to RFC7517.

Creating the keys and the JWKS depends on the programming language and frameworks you use. We provide basic Java code samples at the end of this page in section "Code samples". You also might want to check out jwt.io for libraries fitting your needs.
Make sure you have

    picked the appropriate scopes. The client credentials grant is not available for all scopes. Please refer to our Swaggers, which indicate the scopes that allow the use of this grant. You find them in the security definitions as api_client_credential. Check out also our Products by selecting the authorisation method to "OAuth2.0 - Client Credential" on the filter to find out which various products are available for this grant type.
    uploaded the public key of your app as part of a JSON Web Key Set (JWKS) in our Developer Portal. You can do so when creating or updating an app there.
    access to your private key.

1. Create a signed JWT

Creating a signed JWT depends heavily on the programming language and frameworks you use to develop your application. We provide a basic Java code sample below.

The JWT needs some mandatory information in it's claimset. Your application's client id needs to be provided in the issuer field (iss) and the subject field (sub). You can find the client id in details of the app on our Developer Portal. The audience field (aud) must match the token URI of the dbAPI authorisation service. Lastly you should provide an expiry timestamp until when the JWT is considered valid. The expiration time field (exp) carries the seconds since the beginning of the UNIX epoch.

An example of a claim set used on the dbAPI simulation environment could look like this:

{
  "aud": "https://simulator-api.db.com/gw/oidc/token",
  "sub": "your_client_id",
  "iss": "your_client_id",
  "exp": 1592497316
}

The claim set needs to be attached to a JSON Web Signature Header (JWS) which describes the used signature algoritm, such as SHA-256. The so formed JWT is then signed as described in RFC7523. For details on the supported signing algorithms see below section.

The dbAPI authorisation service expects the signed JWT as Base64URL encoded string. Above example would look like this:

eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJ5b3VyX2NsaWVudF9pZCIsImF1ZCI6Imh0dHBzOlwvXC9zaW11bGF0b3ItYXBpLmRiLmNvbVwvZ3dcL29pZGNcL3Rva2VuIiwiaXNzIjoieW91cl9jbGllbnRfaWQiLCJleHAiOjE1OTI0OTczMTZ9.3KcIk8_NlJ6b5n2W34hv1tk1Gndr9uAtRDHYqsiE2HGb7yfjQ_xRCQdmSNjaT5vKzbJ6bB6vR58ondigaUzf7g

2. Request access token

Your app needs to authenticate itself by presenting a client assertion to the dbAPI authorisation service. The client assertion is the signed JWT as Base64URL encoded string - just as you created it in the previous step. In addition your app must send a grant type parameter and a client assertion type parameter.

For this your app makes a POST request to the dbAPI authorisation service under /gw/oidc/token. The following parameters must be sent in the body using the application/x-www-form-urlencoded format:
Body parameter 	Description
grant_type 	Required. The grant type you have to provide to request the access token is client_credentials.
client_assertion_type 	Required. Set it to urn:ietf:params:oauth:client-assertion-type:jwt-bearer.
client_assertion 	Required. This is the signed JWT as a Base64URL serialized string as previously described.
scope 	Optional. You can provide a space-separated scope list to narrow down the usage of the access token.

Let's take a look at an example:

POST https://simulator-api.db.com/gw/oidc/token Content-Type: application/x-www-form-urlencoded grant_type=client_credentials&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer &client_assertion=eyJhbGciOiJSUzI1NiJ9[...]pOUbKw

If the application is set up correctly, the response will be HTTP OK with a JSON like this:

{
  "access_token": "eyJraWQiOiJzaWduZXIyMDIwLWVjIiwiYWxnIjoiRVMyNTYifQ.eyJzdWIiOiI0MTcyN2QwNS0yYjk3LTQxM2YtYTdmNy1kNzcwNzA5YWJiOGIiLCJhenAiOiI0MTcyN2QwNS0yYjk3LTQxM2YtYTdmNy1kNzcwNzA5YWJiOGIiLCJpc3MiOiJodHRwczpcL1wvdWF0MS5zaW11bGF0b3ItYXBpLmRiLmNvbVwvZ3dcL29pZGNcLyIsImV4cCI6MTU5MjgzNTIwMiwiaWF0IjoxNTkyODM0NjAyLCJqdGkiOiI3ZTI5NTQ0My02YmM2LTRmZDQtOGM3NC04N2EzNjdiNGZiY2QifQ.dhboxuT1wA7aZlMumfjYGKVxNbX0u9wGIosizttUjc-cujPfyFv3BA6h7PoW64MkekNrbmGcheMJgOasEWpO5w",
  "token_type": "Bearer",
  "expires_in": 599,
  "scope": "investments_report read_security_transactions open_cash_account read_assets read_performances order_securities create_processing_orders"
}

Its content is straight-forward:
Key 	Key type 	Description
access_token 	string 	An access token to be used in subsequent calls to access dbAPI services.
token_type 	string 	The token type is always 'Bearer'.
expires_in 	string 	The lifetime of the access token in seconds.
scope 	string 	Space-separated list of scopes the access token can be used for

In case something went wrong, your app will receive a non HTTP OK and an error message depending on the issue.
3. Parse and validate the access token

Your application should parse and validate the access token before executing requests to the Deutsche Bank API Program endpoints to make sure the access token isn’t compromised and the signature is authentic. You can parse and validate JWTs e.g. by:

    Using any existing middleware for your web framework
    Choosing a third-party library from JWT.io
    Manually implementing the checks described in RFC 7519.

We strongly recommend that you use middleware or one of the existing third-party libraries to parse and validate JWTs instead of manually implementing the checks to avoid potential security vulnerabilities.
4. Use the access token to execute requests to the Deutsche Bank API Program endpoints

After parsing and validating the access token, you can execute requests to our dbAPI endpoints. You have to provide the HTTP header "Authorization: Bearer <access-token>" during the endpoint calls. Check out our Products by selecting the authorisation method to "OAuth2.0 - Client Credential" on the filter to find out which products are available for this grant type. As a response you should get the appropriate information in JSON format.
Supported JWT signing algorithms

The following algorithms can be used for signing the JWTs used as a client assertion.
Elliptic Curve algorithms

The supported ECDSA signature algorithms are a combination of an elliptic curve and a hash function. These are supported:

    Curve P-256 and SHA256
    Curve P-384 and SHA384
    Curve P-521 and SHA512

The ECDSA signature is combined with the message encoding according to ANSI X9.62, NIST.FIPS.186-4.
Code samples

To give you an idea how to handle JSON Web Keys, Tokens and Key sets we provide some basic Java code samples here. If you work with other programming languages you might find the library collection on jwt.io helpful.
Creating a JSON Web Key and a JSON Web Key set

Here we create a ECCDSA P-256 (NIST-256) JWT using the Nimbus JOSE+JWT library and put it into a JWKS.

// Generate the ECCDSA-256 key pair
KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("EC");
keyPairGenerator.initialize(Curve.P_256.toECParameterSpec());
KeyPair ecKeyPair = keyPairGenerator.generateKeyPair();

// Build a JWK from it
JWK ecJwk = new ECKey.Builder(Curve.P_256, (ECPublicKey)ecKeyPair.getPublic())
    .privateKey((ECPrivateKey) ecKeyPair.getPrivate())
    .keyID("your-key-id") // Give the key some ID (optional)
    .keyUse(KeyUse.SIGNATURE)  // Mark the intended usage of this key (optional)
    .build();

// Put the JWK into a JWKS
JWKSet jwkSet = new JWKSet(ecJwk);

System.out.println("Public version of JWKS - use this to upload on our Developer Portal:");
System.out.println(jwkSet.toJSONObject(true).toJSONString());

System.out.println("Private version of JWKS - keep this to yourself:");
System.out.println(jwkSet.toJSONObject(false).toJSONString());

The above code should print out the newly created JWKS in two flavours. One contains only the public key parts and is suited for upload on the Developer Portal:

{
  "keys": [{
    "kty": "EC",
    "use": "sig",
    "crv": "P-256",
    "kid": "your-key-id",
    "x": "qW1ft5O5XAIwzN6EiFsWQOybKaVSyiW7WkuZzzSsvRw",
    "y": "S7AA5oH6ROUAxtJtEEzLEY4cOnp-zTbrkslf28zbJrI"
  }]
}

The other also contains the private key part, so keep it confidential:

{
  "keys": [{
    "kty": "EC",
    "d": "p_5Tv28xxH4szne47KAgwZEbIbZEkGctUp4ivDIuCBE",
    "use": "sig",
    "crv": "P-256",
    "kid": "your-key-id",
    "x": "qW1ft5O5XAIwzN6EiFsWQOybKaVSyiW7WkuZzzSsvRw",
    "y": "S7AA5oH6ROUAxtJtEEzLEY4cOnp-zTbrkslf28zbJrI"
  }]
}

Creating a signed JWT

Here we create a ECCDSA P-256 JWT using the Nimbus JOSE+JWT library and sign it with a private key using the SHA-256 algorihm.

    // Pull in the JWK with your private key from config or other
    JWK ecJwk = ...

    // Assume we deal with a Elliptic Curve key here
    ECKey ecKey = ecJwk.toECKey();

    // Prepare JWT with a claims set, set some expiration date
    String clientId = "your_client_id";
    JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
        .subject(clientId) // Subject and Issuer field must be filled with your client id
        .issuer(clientId)
        .audience("https://simulator-api.db.com/gw/oidc/token") // The Audience must match the used dbAPI authorisation service endpoint
        .expirationTime(Date.from(LocalDateTime.now().plusHours(1).atZone(ZoneId.systemDefault()).toInstant())) // This JWT should expire in 1h
        .build();

    // Attach a header descibring the used signing algorithm
    SignedJWT signedJWT = new SignedJWT(
        new JWSHeader(JWSAlgorithm.ES256),
        claimsSet);

    // Create the EC signer using your private key
    ECPrivateKey ecPrivateKey = ecKey.toECPrivateKey();
    JWSSigner signer = new ECDSASigner(ecPrivateKey);

    // Compute the EC signature
    signedJWT.sign(signer);

    // Serialize the JWS to BASE64URL encoded form
    String base64UrlEncodedJWT = signedJWT.serialize();
  
    // Use it ;)
    System.out.println(base64UrlEncodedJWT);
    
    

Refresh token grant

The refresh token grant type is used to get a new access token from a refresh token. Access tokens are short-lived and valid for 600 seconds = 10 minutes. If you want to keep user interaction to a minimum and need to access the dbAPI endpoints longer than the access token expiry time of 10 minutes, you should use the refresh token grant. The refresh token expires after 15552000 seconds = 180 days.

The refresh token is obtained only by using the Authorisation code grant with PKCE first. Although it's still possible to use the Authorisation code grant first to receive refresh tokens, we strongly recommend to use the PKCE extension with this grant type.

Note: Just confidential clients are allowed to use the refresh token grant because these clients have a client secret only. The Deutsche Bank API Program doesn't support the usage of refresh tokens with other grant types.
1. Request to get an access token from a given refresh token

The header of this POST request must contain the following parameter:
Header parameter 	Description
Authorization 	Required. Base64 encoded string that contains the Client ID and Client Secret Key, prefixed by the HTTP authorisation keyword: Authorization: Basic <your_client_id>:<your_client_secret>

You need to send the following parameters using the 'application/x-www-form-urlencoded' format in the HTTP request entity-body:
Body parameter 	Description
grant_type 	Required. Set the value to 'refresh_token'.
refresh_token 	Required. The refresh token that you have obtained as part of the authorisation code grant flow.
scope 	Optional. The scope of the access request as described by RFC6749:Section 3.3.

Let's take a look at an example:

POST https://simulator-api.db.com/gw/oidc/token Authorization: Basic UzZ3...Pc25IUzZ3 Content-Type: application/x-www-form-urlencoded grant_type=refresh_token&refresh_token=eyJraWQiOiJyc2ExIiwiYWxnIjoiUlMy...

2. Response from our authorisation service
Key 	Key Type 	Description
access_token 	string 	An access token to be used in subsequent calls to use Deutsche Bank API Program services.
token_type 	string 	The token type is always 'Bearer'.
expires_in 	string 	The lifetime of the access token in seconds.

Let's look at an example here:

{
  "access_token": "eyJraWQiOiJyc2ExIiwiYWxnIjoiUlMy...",
  "token_type": "Bearer",
  "expires_in": 599
}

3. Parse and validate the access token

Your application should parse and validate the access token before executing requests to the Deutsche Bank API Program endpoints to make sure the access token isn’t compromised and the signature is authentic. You can parse and validate JWTs e.g. by:

    Using any existing middleware for your web framework
    Choosing a third-party library from JWT.io
    Manually implementing the checks described in RFC 7519.

We strongly recommend that you use middleware or one of the existing third-party libraries to parse and validate JWTs instead of manually implementing the checks to avoid potential security vulnerabilities.
4. Use the access token to execute requests to the Deutsche Bank API Program endpoints

After parsing and validating the access token, you use the access token to execute requests to get information about cash accounts for example. To access our endpoints, you have to provide the HTTP header "Authorization: Bearer <access-token>" during the endpoint calls. As a response you should get information of the customer in JSON format.


Available Scopes

The Deutsche Bank API Program allows access to customer data or customer related functionalities. As we value the privacy of our customers, every request to the api requires authorization. Using industry standards like OAuth2.0 and OpenID Connect, we give our customers the means to control which application can access what data.

The OAuth2.0 standard provides the so called scopes for that. By approving (or not approving) certain scopes, the customer can select which data a client app can access (or not access). The customer can also revoke access to certain data they have given before by revoking the appropriate scopes.

As a rule of thumb, choose the most restrictive set of scopes possible for your usecase and avoid requesting scopes that your app does not actually need. Also make sure to educate the customer why your app wants to get certain scopes granted.

By the OAuth2.0 standard, the scopes available are independent by the grant type a client app uses. However, we offer some scopes with certain grant types only. Here’s a list of scopes that are available.
Authorization Code
Grant Type
Scope	Description
investments_report	Generate investments report for the given customer.
openid	Request access to OpenId Connect functionality
read_accounts	Grants read access to all basic cash account data like the current balance and a general account overview for the given customer.
offline_access	Request an OAuth2 Refresh Token
read_ownership_information	Information about ultimate beneficiary owners
sepa_credit_transfers	Initiate and check status of Sepa Credit Transfers
read_additional_organization_data	Grants read access to additional organizational information about a partner representing a company. The additional data contains legal form, industry, local court, stakeholders and tax identification.
verify_account_ownership	Performs account verification for the given customer.
sepa_direct_debit_core	Initiate and check status of SEPA Direct Debit Core
read_partners_legi	Grants read access to legitimation data of the current partner/customer. This data is only available for natural persons. Legitimation data contains information, e.g. about the document type, document number and document issue date for the given customer.
rent_analysis	Check rent payments
read_check_information	Know-Your-Customer Information
read_legal_representatives_data	Information about legal representatives
transaction_notifications	Enable the transaction subscription feature
read_credit_cards_list_with_details	Grants read access to credit card data.
read_customer_data	Performs personal data verification for the given customer.
read_partners	Grants read access to basic data of the current partner/customer. The basic partner data contains, among other information, the first name, the surname and the birthdate for the given customer. There is some overlap between our /partners endpoint and the /userinfo endpoint provided by OpenID connect.
order_securities	Order securities
sepa_direct_debit_B2B	Initiate and check status of SEPA Direct Debit B2B
read_assets	Grants read access to asset summary of a portfolio group.
read_performances	Grants read access to performance overview of a portfolio.
instant_sepa_credit_transfers	Initiate and check status of instant SEPA credit transfers
read_credit_card_transactions	Read your credit card transaction data
read_additional_personal_data	Grants read access to additional data about the partner. The additional data currently contains the tax identifications for the given customer.
read_addresses	Grants read access to address data for the given customer. Two address types are currently supported: business address and private address.
read_accounts_list	Grants read access to basic cash account data and a general account overview for the given customer.
age_certificate	Grants a check of a person's age, when compared against a specific minimum age
read_security_accounts_list	Grants read access to security account data.
read_transactions	Grants read access to transactions for cash accounts (current and deposit) for the given customer. The API provides in default up to 13 months of transaction history.
bulk_sepa_credit_transfer	Bulk Sepa Credit Transfer with status check
read_security_transactions	Grants read access to all security transactions for the given customer.
investments_orders_status_notification	Enable the investments orders subscription feature
income_analysis	Check income payments

All available scopes are also documented in the swagger file provided; see the Explorer. 



Client Credentials
Grant Type
Scope	Description
read_credit_card_transactions	Read your credit card transaction data
reserve_branch_customer_number	Reserve Branch Customer Number
investments_report	Generate investments report for the given customer.
open_escrow_account	Escrow account openings
sepa_credit_transfers	Initiate and check status of Sepa Credit Transfers
open_cash_account	Cash account openings
read_transactions	Grants read access to transactions for cash accounts (current and deposit) for the given customer. The API provides in default up to 13 months of transaction history.
bulk_sepa_credit_transfer	Bulk Sepa Credit Transfer with status check
sepa_direct_debit_core	Initiate and check status of SEPA Direct Debit Core
read_partners_legi	Grants read access to legitimation data of the current partner/customer. This data is only available for natural persons. Legitimation data contains information, e.g. about the document type, document number and document issue date for the given customer.
read_security_transactions	Grants read access to all security transactions for the given customer.
transaction_notifications	Enable the transaction subscription feature
investments_orders_status_notification	Enable the investments orders subscription feature
read_credit_cards_list_with_details	Grants read access to credit card data.
read_brand	Grants permission to get data from the /brand endpoint. Only available with client credential grant flow right now.
request_private_loans	Request loans
order_securities	Order Securities
sepa_direct_debit_B2B	Initiate and check status of SEPA Direct Debit B2B
create_processing_orders	Grants permission to post data with the /processingOrders endpoint. Only available with client credential grant flow right now.
read_assets	Grants read access to asset summary of a portfolio group.
read_performances	Grants read access to performance overview of a portfolio.
instant_sepa_credit_transfers	Initiate and check status of instant SEPA credit transfers
open_esp_securities_account	Open ESP securities accounts

All available scopes are also documented in the swagger file provided; see the Explorer. 

Tutorial

This is a step by step guide explaining what you have to do to call an endpoint and get access to the simulation environment. For this purpose, we use the cashAccounts endpoint. It also executes and explains the OAuth2.0 authorization code grant with PKCE flow described in our documentation.

To run this application Java 8 or higher is required. This application uses Jersey 3 because the dbAPI uses the REST architectural style for all of it's endpoints. Other libraries are just helper libraries which are needed by the sample application like Jakarta Activation For generating the code challenge Codec is used.

Prerequisites :

    Registration on the Developer portal and log in
    Create a Deutsche Bank test application which uses the authorization code grant with PKCE as grant type.
    Create a Deutsche Bank test user to authorize

Download
Download Source
Pre required step 0.1 - create a code verifier

Generates a random Base64 encoded code verifier which has to be used in Step 5 as a request parameter.
Pre required step 0.2 - create a code challenge from your code verifier

Produces a code challenge from a code verifier, to be hashed with SHA-256 and encode it with Base64 to be URL safe. This code challenge has to be used in Step 1 as request parameter.
Step 1 - OAuth2.0 initial authorization request

1.1 Executes the OAuth2.0 initial authorization request.

1.2 Saves the session in a Cookie. Saving the session is optional and not part of the OAuth2.0 specification!

The scope request parameter is optional. The state request parameter is optional too but recommended to e.g., increase the application's resilience against CSRF attacks. All other request parameter are required!
Step 2 - Redirect to the login page

2.1 Redirect to the login page

2.2 Updating the session in the cookie.

2.3 Return an array which contains the URI and the response from the redirection.
Step 3.1 - Login

Executes the login with your defined test users' fkn and pin and updates the session (see above). The responseAndRedirectUri parameter contains the response and the URI from Step 2. The username parameter is the fkn from your selected test user. The password is the pin of your selected test user.

Return the response after the login.
Step 3.2 - Grant Access

Authorize access with the requested scope(s) in a Deutsche Bank prompted screen (consent screen). The scope (read_accounts) was requested in Step 1. The response parameter is the response after the login from Step 3.1.

Return the response after authorize and give access for the allowed scope (read_accounts).
Step 4 - Redirection - receive the code

After successful authorization in Step 3 get the code from the HTTP location attribute of the response. Return the code or null (in case of an error).
Step 5 - Request access token

Request the access token with given code from Step 4. Use the provided code verifier from pre defined Step 0.1. Return the Bearer access token in JSON format.
Step 6 - Extract access token

Extract the access token from the JSON response of the Deutsche Bank authorization service. Return the Bearer access token as String.
Step 7 - Call the cash accounts endpoint

Call the cash accounts endpoint to get the available cash accounts from your test users' account. You should receive at least one cash account, depending on which test user you choose. The parameter "accessToken" is the Bearer token from Step 6.
Helper methods for the code snippets

Code snippet to update the session id from a HTTP response:

Just for internal use to avoid potential CSRF attacks. You can read the RFC against CSRF attacks here: https://tools.ietf.org/html/rfc6749. The parameter "webPage" is the login or consent screen.

Get URI that is called from action in given HTML page. The URI is the target from the webPage. The parameter "webPage" is the login or consent screen.

Extract the code from given string.

Get first match from given String.
Summary - What did we do?

    We have used and documented the OAuth2.0 authorization code grant with PKCE flow.
    We successfully called an endpoint of Deutsche Bank API Program (cash accounts).

Notice and license
Notice and license

Certificate based Authentication

Some APIs only allow certificate based authentication.
Generally

During the app creation as well as the go-live request you will be asked to provide:

    the complete SSL certificate trust chain

    in .pem format (either manually or via file upload)

    in the following order:

    --BEGIN CERTIFICATE-- (The primary SSL certificate: your_domain_name.crt)
    --END CERTIFICATE--
    --BEGIN CERTIFICATE-- (The intermediate certificate: intermediateCert.crt) --END CERTIFICATE-- --BEGIN CERTIFICATE-- (The root certificate: trustedRoot.crt) --END CERTIFICATE--

You need to use 2-way TLS for the connection to the API and the according certificate.
Keep in mind

For the go-live process (production access) you need a certificate that has not been used for simulation.

    This certificate needs to have extended validation (EV)


