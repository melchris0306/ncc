({
  checkObjectHelper: function (component) {
    console.log("IN");
    var action = component.get("c.checkObject");
    action.setParams({
      objId: component.get("v.journeyID")
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      console.log("!@#STATE: " + state);
      if (state === "SUCCESS") {
        var res = response.getReturnValue();
        console.log(">>>>>", res);
        if (res == "Journey__c") {
          this.toggleCmp(component, "validateLogin");
        }
      } else if (state == "ERROR") {
        var errors = response.getError();
        component.set("v.showErrors", true);
        component.set("v.errorMessage", errors[0].message);
        console.log("ERROR", errors[0].message);
      }
    });
    $A.enqueueAction(action);
  },

  toggleCmp: function (component, cmpName) {
    var cmp = component.find(cmpName);
    $A.util.toggleClass(cmp, "slds-hide");
    $A.util.toggleClass(cmp, "slds-show");
  },

  getURLParameters: function (component) {
    var url = new URL(window.location.href);

    var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
    var sURLVariables = sPageURL.split("&"); //Split by & so that you get the key value pairs separately in a list
    var sParameterName;
    var i;

    for (i = 0; i < sURLVariables.length; i++) {
      sParameterName = sURLVariables[i].split("="); //to split the key from the value.

      if (sParameterName[i] === "journeyId") {
        //sParameterName[1] === undefined ? 'Not found' : sParameterName[1];
        component.set("v.journeyID", sParameterName[1]);
      }
    }
  },

  validateEmailHelper: function (component) {
    //console.log(component.get("v.validateParticipant"));
    var action = component.get("c.validateParticipant");
    action.setParams({
      inputEmail: component.get("v.inputEmail"),
      journeyId: component.get("v.journeyID")
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      console.log("!@#STATE: " + state);
      if (state === "SUCCESS") {
        var res = response.getReturnValue();
        console.log(">>>>>", res);

        if (res == "false") {
          this.showToast(
            component,
            "Error!",
            "Participant not found. Kindly reach out to your administrator.",
            "error"
          );
        } else {
          window.open(res, "_self");
        }
      } else if (state == "ERROR") {
        var errors = response.getError();
        component.set("v.showErrors", true);
        component.set("v.errorMessage", errors[0].message);
        console.log("ERROR", errors[0].message);
        this.showToast(
          component,
          "Error!",
          "Oops! An unexpected error occurred. Kindly reach out to your administrator.",
          "error"
        );
      }
    });
    $A.enqueueAction(action);
  },

  showToast: function (component, status, message, type) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: status,
      message: message,
      type: type
    });

    toastEvent.fire();
  }
});