({
    doInit: function (component, event, helper) {
    // Get the record ID attribute
        var recordId = component.get("v.recordId");
    
        // Use window.location.href instead of e.force:navigateToSObject because this is not supported
        // when the flow is triggered via a custom action
        window.location.href = '/' + recordId;
 }})