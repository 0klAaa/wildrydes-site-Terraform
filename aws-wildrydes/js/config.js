window._config = {
    cognito: {
        userPoolId:       '<terraform output cognito_user_pool_id>',
        userPoolClientId: '<terraform output cognito_user_pool_client_id>',
        region:           '<ma région - normalement eu-west-1>'
    },
    api: {
        invokeUrl: '<terraform output api_invoke_url>',
    }
};