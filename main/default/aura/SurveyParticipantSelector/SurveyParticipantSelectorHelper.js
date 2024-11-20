({
  getParticipants: function (component, event, helper) {
    let surveyId = component.get("v.recordId");
    let action = component.get("c.getContactsFromSurveyParticipants");

    action.setParams({
      recordId: surveyId
    });

    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        component.set("v.listOfSelectedRecords", response.getReturnValue());
      } else {
        helper.showToast(
          "Error",
          helper.showToastError(helper.logError(response.getError())),
          "error"
        );
      }
    });

    $A.enqueueAction(action);
  },

  saveParticipants: function (component, event, helper) {
    let surveyId = component.get("v.recordId");
    let contacts = component.get("v.listOfSelectedRecords");
    let action = component.get("c.saveSelectedParticipants");
    let contactsToProcess = [];

    for (let i = 0; i < contacts.length; i++) {
      contactsToProcess.push(contacts[i].Id);
    }

    action.setParams({
      objectIds: contactsToProcess,
      recordId: surveyId
    });

    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        helper.showToast(
          "Success!",
          "Contacts have successfully been processed",
          "success"
        );
        $A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
      } else {
        helper.showToast(
          "Error",
          helper.showToastError(helper.logError(response.getError())),
          "error"
        );
      }
    });

    $A.enqueueAction(action);
  },

  showToast: function (title, message, type) {
    let toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: title,
      type: type,
      message: message
    });
    toastEvent.fire();
  },

  logError: function (errors) {
    if (errors) {
      if (errors[0] && errors[0].message) {
        let errorMessage = "Error message: " + errors[0].message;
        return errorMessage;
      } else {
        return "Unknown error", JSON.stringify(errors);
      }
    } else {
      return "Unknown error", JSON.stringify(errors);
    }
  }
});