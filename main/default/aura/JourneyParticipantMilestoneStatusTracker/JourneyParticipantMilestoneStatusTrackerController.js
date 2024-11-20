/**
 * Created by angelorivera on 8/7/2022.
 */

({

    doInit : function(cmp) {
        var action = cmp.get('c.getJourneyParticipantInfo');
        action.setParams({
            participantId : cmp.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("------ response state: " + state);

            var participant = response.getReturnValue();
            cmp.set("v.JourneyParticipant", participant);


            var milestones = participant.mapTotalNumberOfMilestoneStatus;
            var iStartedMstones = parseInt(participant.startedParticipantMilestones) - parseInt(participant.completedParticipantMilestones);
            console.log('iStartedMstones: ' + iStartedMstones);
            cmp.set("v.startedMilestones", iStartedMstones);

            if (state === "SUCCESS") {
                var milestoneStatus = [];

                for(var stat in milestones){
                    milestoneStatus.push({value:milestones[stat], key:stat});
                    console.log("Status:" + stat + " - " + milestones[stat]);
                }
                cmp.set("v.milestoneStats", milestoneStatus);
                console.log(milestoneStatus);

            }
        });
        $A.enqueueAction(action);
    }

});