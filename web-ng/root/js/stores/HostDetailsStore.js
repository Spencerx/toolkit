// Make sure jquery loads first
// assumes Dispatcher has already been declared (so load that first as well)

var HostDetailsStore = {
    hostDetails: null,
    detailsTopic: 'store.change.host_details',
};

HostDetailsStore.initialize = function() {
    HostDetailsStore._retrieveDetails();

};

HostDetailsStore._retrieveDetails = function() {
    $.ajax({
            url: "services/host.cgi?method=get_details",
            type: 'GET',
            contentType: "application/json",
            dataType: "json",
            success: function (data) {
                HostDetailsStore.hostDetails = data;
                Dispatcher.publish(HostDetailsStore.detailsTopic);
            },
            error: function (jqXHR, textStatus, errorThrown) {
                console.log(errorThrown);
            }
        });
};

HostDetailsStore.getHostDetails = function() {
    return HostDetailsStore.hostDetails;
};

HostDetailsStore.getHostInterfaces = function() {
    return HostDetailsStore.hostDetails.interfaces;
};

HostDetailsStore.getAutoUpdates = function() {
    return HostDetailsStore.hostDetails.auto_updates;
};

HostDetailsStore.getAllowInternalAddresses = function() {
    return HostDetailsStore.hostDetails.allow_internal_addresses;
};

HostDetailsStore.initialize();
