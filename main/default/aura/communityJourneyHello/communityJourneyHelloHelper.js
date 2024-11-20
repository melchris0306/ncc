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
          component.set("v.urlFromJourney", userJourneyWrapper.urlFromJourney);
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
  }
});