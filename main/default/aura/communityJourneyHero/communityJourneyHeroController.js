({
  openModel: function (component, event, helper) {
    // for Display Model,set the "isOpen" attribute to "true"
    component.set("v.isOpen", true);
  },

  closeModel: function (component, event, helper) {
    // for Hide/Close Model,set the "isOpen" attribute to "Fasle"
    component.set("v.isOpen", false);
  },

  doInit: function (component, event, helper) {
    var url = new URL(window.location.href);

    var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
    var sURLVariables = sPageURL.split("&"); //Split by & so that you get the key value pairs separately in a list
    var sParameterName;
    var i;

    for (i = 0; i < sURLVariables.length; i++) {
      sParameterName = sURLVariables[i].split("="); //to split the key from the value.
      console.log("!@# Parameter:" + sParameterName);
      if (sParameterName[i] === "journeyId") {
        //sParameterName[1] === undefined ? 'Not found' : sParameterName[1];
        component.set("v.journeyID", sParameterName[1]);
      }
    }

    var journeyId;

    if (component.get("v.journeyID") == null) {
      journeyId = "a5J03000000L08NEAS";
    } else {
      journeyId = component.get("v.journeyID");
    }

    console.log("!@# journeyID: " + journeyId);

    helper.getUserJourney(component, journeyId);
  },

  //Added by: Kyzer Buhay - 05/01/2021
  onClickAvatarHandler: function (component, event, helper) {
    component.set("v.uploadImageModal", true);
  },

  closeAvatarUploadModal: function (component, event, helper) {
    component.set("v.uploadImageModal", false);
  },

  onClickSubmit: function (component, event, helper) {
    component.set("v.showSpinner", true);
    helper.createTask(component);
  },

  onClickConfirm: function (component, event, helper) {
    component.set("v.submitConfirmationMdl", false);
  },

  formValidation: function (component, event, helper) {
    let formFields = {
      fName: component.get("v.userJourney.Contact__r.FirstName"),
      lName: component.get("v.userJourney.Contact__r.LastName"),
      email: component.get("v.userJourney.Contact__r.Email"),
      phone: component.get("v.userJourney.Contact__r.Phone"),
      subject: component.get("v.userSubject"),
      comment: component.get("v.userComment")
    };
    if (
      !$A.util.isEmpty(formFields.fName) &&
      !$A.util.isEmpty(formFields.lName) &&
      !$A.util.isEmpty(formFields.email) &&
      !$A.util.isEmpty(formFields.phone) &&
      !$A.util.isEmpty(formFields.subject) &&
      !$A.util.isEmpty(formFields.comment)
    ) {
      component.set("v.disableSubmit", false);
    } else {
      component.set("v.disableSubmit", true);
    }
  }
});