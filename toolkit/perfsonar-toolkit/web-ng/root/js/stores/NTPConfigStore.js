// Make sure jquery loads first
// assumes Dispatcher has already been declared (so load that first as well)

var NTPConfigStore = {
    ntpConfig: null,
    ntpConfigTopic: 'store.change.ntp_config',
    ntpConfigErrorTopic: 'store.ntp_config.save_error',
};

NTPConfigStore.initialize = function() {
    NTPConfigStore._retrieveNTPConfig();
};

NTPConfigStore._retrieveNTPConfig = function() {
    $.ajax({
            url: "services/ntp.cgi?method=get_ntp_config",
            type: 'GET',
            contentType: "application/json",
            dataType: "json",
            success: function (data) {
                NTPConfigStore.ntpConfig = data;
                Dispatcher.publish(NTPConfigStore.ntpConfigTopic);
            },
            error: function (jqXHR, textStatus, errorThrown) {
                console.log(errorThrown);
                Dispatcher.publish( NTPConfigStore.ntpConfigErrorTopic, errorThrown );
            }
        });
};

NTPConfigStore.getNTPConfig = function() {
    return NTPConfigStore.ntpConfig;
};

NTPConfigStore.getNTPSelectedServers = function() {
    return NTPConfigStore.ntpConfig.selected_servers;
};

NTPConfigStore.getNTPKnownServers = function() {
    return NTPConfigStore.ntpConfig.known_servers;
};

NTPConfigStore.initialize();
