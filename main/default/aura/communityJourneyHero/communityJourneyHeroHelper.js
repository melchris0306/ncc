({
  getUserJourney: function (component, journeyId) {
    var userJourney = component.get("c.getUserJourney");
    userJourney.setParams({
      strJourneyId: journeyId
    });

    userJourney.setCallback(this, function (response) {
      var state = response.getState();
      console.log("!@#STATE: " + state);
      if (state === "SUCCESS") {
        var userJourneyWrapper = response.getReturnValue();
        console.log("!@#urlFromJourney: " + userJourneyWrapper.urlFromJourney);
        if (userJourneyWrapper.urlFromJourney === false) {
          component.set("v.userJourney", userJourneyWrapper.userJourney);

          component.set(
            "v.userJourneyFirstName",
            userJourneyWrapper.userJourney.Contact__r.FirstName
          );
          component.set(
            "v.userJourneyLastName",
            userJourneyWrapper.userJourney.Contact__r.LastName
          );

          component.set("v.urlFromJourney", userJourneyWrapper.urlFromJourney);

          let campaignLogo = "";
          campaignLogo = userJourneyWrapper.CampaignLogoURL;
          component.set("v.campaignLogoURL", campaignLogo);

          let journeyImage = "";
          journeyImage = userJourneyWrapper.JourneyLogoURL;
          component.set("v.journeyImageURL", journeyImage);

          if (userJourneyWrapper.lstUserMilestones !== undefined) {
            component.set(
              "v.userMilestones",
              userJourneyWrapper.lstUserMilestones
            );
            if (userJourneyWrapper.mapTasksByMilestoneName !== undefined) {
              var acts = [];
              for (var key in userJourneyWrapper.mapTasksByMilestoneName) {
                acts.push({
                  value: userJourneyWrapper.mapTasksByMilestoneName[key],
                  key: key
                });
                console.log("!@# Milestone: " + key);
              }
              component.set("v.userMilestoneRelatedInfo", acts);
            }
          }
        } else if (userJourneyWrapper.urlFromJourney === true) {
          component.set(
            "v.journeyMilestoneList",
            userJourneyWrapper.journeyMilestoneList
          );
        }
        component.set("v.journeyData", userJourneyWrapper.journeyData);
      } else {
        console.log("!@# User Journey not found!");
      }
    });
    $A.enqueueAction(userJourney);
  },

  createTask: function (component) {
    //01057
    //In Progress - Task Creation
    //Assign task to Kate Hegwood and Relate to user Journey
    var taskCreation = component.get("c.createTaskContactUs");
    taskCreation.setParams({
      fName: component.get("v.userJourney.Contact__r.FirstName"),
      lName: component.get("v.userJourney.Contact__r.LastName"),
      email: component.get("v.userJourney.Contact__r.Email"),
      phone: component.get("v.userJourney.Contact__r.Phone"),
      userJourney: component.get("v.journeyData").Id,
      subject: component.get("v.userSubject"),
      comment: component.get("v.userComment")
    });

    taskCreation.setCallback(this, function (response) {
      var state = response.getState();
      let hasError = response.getReturnValue();
      if (state === "SUCCESS" && !hasError) {
        //When successful, show confirmation message
        component.set("v.submitConfirmationMdl", true);
        component.set(
          "v.taskCreationResult",
          " We have received your meessage and will be in touch soon. Thank you."
        );
        component.set("v.submitConfirmationBtn", "Done");
        component.set("v.isOpen", false);
      } else {
        component.set(
          "v.taskCreationResult",
          " Something went wrong. Please try again later. "
        );
        component.set("v.submitConfirmationBtn", "Got it");
      }
      component.set("v.showSpinner", false);
      this.clearContactUsForm(component);
    });
    $A.enqueueAction(taskCreation);
  },

  clearContactUsForm: function (component) {
    component.set("v.userSubject", "");
    component.set("v.userComment", "");
  }
});