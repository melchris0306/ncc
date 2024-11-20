/**
 * Created by JL on 01/19/2021.
 */

({
  doInit: function (component, event, helper) {
    var action = component.get("c.fetchObjectAndFieldPrefix");
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = response.getReturnValue();
        if (result.errorMsg === "") {
          let surveyObj = {
            SurveyObjectAPI: result.surveyObjectPrefix,
            SurveyActiveFieldAPI: result.activeFieldPrefix,
            SurveyEventFieldAPI: result.eventFieldPrefix,
            SurveyDisclaimerFieldAPI: result.disclaimerFieldPrefix
          };
          component.set("v.surveyObj", surveyObj);
        } else {
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
            title: "Clone Record - Retrieve Data",
            message: result.message,
            type: "error"
          });
          toastEvent.fire();
        }
      }
    });

    $A.enqueueAction(action);
  },
  handleOnLoad: function (cmp, event, helper) {
    //get record
    var action = cmp.get("c.getSurveyDetails");
    action.setParams({
      surveyId: cmp.get("v.recordId")
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = response.getReturnValue();

        // process retrieve data
        if (result != null && !result.hasError) {
          if (result.data != null) {
            cmp.set("v.oldRecord", result.data);
            cmp.set("v.newRecord", result.data);

            var newRecord = cmp.get("v.newRecord");
            // prepopulate input fields
            var nameFieldValue = cmp
              .find("nameField")
              .set("v.value", "Copy of " + newRecord.Name);
            var eventFieldValue = cmp
              .find("eventField")
              .set(
                "v.value",
                newRecord[cmp.get("v.surveyObj.SurveyEventFieldAPI")]
              );
            var activeFieldValue = cmp
              .find("activeField")
              .set("v.value", false);
            var disclaimerFieldValue = cmp
              .find("disclaimerField")
              .set(
                "v.value",
                newRecord[cmp.get("v.surveyObj.SurveyDisclaimerFieldAPI")]
              );
            //var milestoneFieldValue = cmp.find("milestoneField").set("v.value", newRecord.Milestone__c);
          }
        } else if (!result.hasError) {
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
            title: "Clone Record - Retrieve Data",
            message: result.message,
            type: "error"
          });
          toastEvent.fire();
        }
      }
    });
    $A.enqueueAction(action);
  },

  doClose: function (component, event, helper) {
    //component.set("v.isOpen", false);
    $A.get("e.force:closeQuickAction").fire();
  },

  doClone: function (cmp, event) {
    event.preventDefault(); // stop the form from submitting
    cmp.set("v.showSpinner", true); //show spinner
    //populate newrecord values for cloning
    var fields = event.getParam("fields");
    var newRecord = cmp.get("v.newRecord");

    newRecord.Name = fields.Name;
    newRecord.Event__c = fields.Event__c;
    newRecord.Active__c = fields.Active__c;
    newRecord.Disclaimer__c = fields.Disclaimer__c;

    var action = cmp.get("c.cloneSurvey");
    action.setParams({
      surveyId: cmp.get("v.recordId"),
      newRecord: newRecord,
      setToActive: false,
      addClonePrefix: false
    });

    action.setCallback(this, function (response) {
      var result = response.getReturnValue();
      var state = response.getState();

      var title, message, type, recordId, hasError;

      if (state === "SUCCESS") {
        var resp = result.split("|");
        hasError = true;
        if (!result.includes("survey cloned")) {
          title = "Error!";
          type = "error";
        } else {
          hasError = false;
          title = "Success!";
          type = "success";
          recordId = resp[1];
        }
        message = resp[0];

        cmp.set("v.showSpinner", false);

        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          title: title,
          message: message,
          type: type
        });
        toastEvent.fire();

        if (!hasError) {
          var navEvt = $A.get("e.force:navigateToSObject");
          navEvt.setParams({
            recordId: recordId,
            slideDevName: "Detail"
          });
          navEvt.fire();
        } else {
          $A.get("e.force:refreshView").fire();
        }
      }
    });
    $A.enqueueAction(action);
  },

  doSave: function (cmp, event) {
    cmp.set("v.showSpinner", true); //show spinner
    var cloneForm = cmp.find("cloneForm");
    var hiddenSubmit = cmp.find("hiddenSubmit");
    cloneForm.submit();
  },

  showToast: function (title, message, type, mode) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: title,
      message: message,
      type: type,
      mode: mode
    });
    toastEvent.fire();
  }
});