# Visit https://aka.ms/teamsfx-v5.0-guide for details on this file
# Visit https://aka.ms/teamsfx-actions for details on actions
version: 1.0.0

provision:
  - uses: aadApp/create # Creates a new Azure Active Directory (AAD) app to authenticate users if the environment variable that stores clientId is empty
    with:
      name: {{appName}} # Note: when you run aadApp/update, the AAD app name will be updated based on the definition in manifest. If you don't want to change the name, make sure the name in AAD manifest is the same with the name defined here.
      generateClientSecret: true # If the value is false, the driver will not generate client secret for you
    writeToEnvironmentFile: # Write the information of created resources into environment file for the specified environment variable(s).
      clientId: AAD_APP_CLIENT_ID
      clientSecret: SECRET_AAD_APP_CLIENT_SECRET # Environment variable that starts with `SECRET_` will be stored to the .env.{envName}.user environment file
      objectId: AAD_APP_OBJECT_ID
      tenantId: AAD_APP_TENANT_ID
      authority: AAD_APP_OAUTH_AUTHORITY
      authorityHost: AAD_APP_OAUTH_AUTHORITY_HOST

  - uses: teamsApp/create # Creates a Teams app
    with:
      name: {{appName}}-${{TEAMSFX_ENV}} # Teams app name
    writeToEnvironmentFile: # Write the information of installed dependencies into environment file for the specified environment variable(s).
      teamsAppId: TEAMS_APP_ID

  - uses: script # Set TAB_DOMAIN for local launch
    name: Set TAB_DOMAIN for local launch
    with:
      run: echo "::set-output TAB_DOMAIN=localhost:53000"
  - uses: script # Set TAB_ENDPOINT for local launch
    name: Set TAB_ENDPOINT for local launch
    with:
      run: echo "::set-output TAB_ENDPOINT=https://localhost:53000"

  - uses: aadApp/update # Apply the AAD manifest to an existing AAD app. Will use the object id in manifest file to determine which AAD app to update.
    with:
      manifestPath: ./aad.manifest.json # Relative path to this file. Environment variables in manifest will be replaced before apply to AAD app
      outputFilePath: ./build/aad.manifest.${{TEAMSFX_ENV}}.json
  # Output: following environment variable will be persisted in current environment's .env file.
  # AAD_APP_ACCESS_AS_USER_PERMISSION_ID: the id of access_as_user permission which is used to enable SSO

  - uses: teamsApp/validateManifest # Validate using manifest schema
    with:
      manifestPath: ./appPackage/manifest.json # Path to manifest template

  - uses: teamsApp/zipAppPackage # Build Teams app package with latest env value
    with:
      manifestPath: ./appPackage/manifest.json # Path to manifest template
      outputZipPath: ./build/appPackage/appPackage.${{TEAMSFX_ENV}}.zip
      outputJsonPath: ./build/appPackage/manifest.${{TEAMSFX_ENV}}.json

  - uses: teamsApp/update # Apply the Teams app manifest to an existing Teams app in Teams Developer Portal. Will use the app id in manifest file to determine which Teams app to update.
    with:
      appPackagePath: ./build/appPackage/appPackage.${{TEAMSFX_ENV}}.zip # Relative path to this file. This is the path for built zip file.
    writeToEnvironmentFile: # Write the information of installed dependencies into environment file for the specified environment variable(s).
      teamsAppId: TEAMS_APP_ID

  - uses: m365Title/acquire # Upload your app to Outlook and the Microsoft 365 app
    with:
      appPackagePath: ./build/appPackage/appPackage.${{TEAMSFX_ENV}}.zip # Relative path to the built app package.
    writeToEnvironmentFile: # Write the information of created resources into environment file for the specified environment variable(s).
      titleId: M365_TITLE_ID
      appId: M365_APP_ID

deploy:
  - uses: prerequisite/install # Install dependencies
    with:
      devCert:
        trust: true
    writeToEnvironmentFile: # Write the information of installed dependencies into environment file for the specified environment variable(s).
      sslCertFile: SSL_CRT_FILE
      sslKeyFile: SSL_KEY_FILE

  - uses: cli/runNpmCommand # Run npm command
    with:
      workingDirectory: .
      args: install --no-audit

  - uses: file/createOrUpdateEnvironmentFile # Generate runtime environment variables
    with:
      target: ./.localSettings
      envs:
        BROWSER: none
        HTTPS: true
        PORT: 53000
        SSL_CRT_FILE: ${{SSL_CRT_FILE}}
        SSL_KEY_FILE: ${{SSL_KEY_FILE}}
        REACT_APP_CLIENT_ID: ${{AAD_APP_CLIENT_ID}}
        REACT_APP_START_LOGIN_PAGE_URL: ${{TAB_ENDPOINT}}/auth-start.html
