({
    doInit : function(cmp, event, helper){
        helper.getCurrentUser(cmp, event, helper);
        helper.initializeDraftEmail(cmp, event, helper);

        //Updated by XenReyes Nov222021 CCN-814
        helper.getRecordSobject(cmp, event, helper);
    },

    handleCloseModal : function(cmp, event, helper){
        //Updated by XenReyes Oct282022 CCN-814
        //helper.closeModal();
        helper.deleteFilesCloseModal(cmp, event, helper);
    },

    handlePrevious : function(cmp, event, helper){
        let currentIndex = cmp.get('v.currentPageIndex');
        cmp.set('v.currentPageIndex', currentIndex > 1 ? --currentIndex : currentIndex);
    },

    handleNext : function(cmp, event, helper){
        helper.validateInputs(cmp, event, helper);
    },

    handleSend : function(cmp, event, helper){

        //CCN-COM-1214-DV XEN REYES Apr. 14, 2022
        cmp.set('v.isSend', true);
        
        helper.setupEmailBody(cmp, event, helper);
        helper.sendCompassEmail(cmp, event, helper);
    },

    handleSaveDraft : function(cmp, event, helper){
        helper.setupEmailBody(cmp, event, helper);
        helper.saveDraft(cmp, event, helper);
    },

    handleCommunicationEmailEvent : function(cmp, event, helper){
        
        //CCN-2861 XEN REYES Apr. 14, 2023
        if(event.getParam("attachmentsList") !== undefined){
            cmp.set("v.attachmentRecords", event.getParam("attachmentsList"));
        }

        //CCN-COM-1214-DV XEN REYES Apr. 14, 2022
        cmp.set("v.options", event.getParam("options"));
        cmp.set("v.excludedIds", event.getParam("excludedIds"));
    },

    handleRecordUpdated : function(cmp, event, helper){
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
            var commsRec = cmp.get("v.commsRecord");
            for (let i in commsRec) {
                let x = i.toLowerCase();
                if(x.includes("journey__c")) if(commsRec[i] !== null || commsRec[i] !== undefined) cmp.set("v.isCommunicationHasJourney", true);
                if(x.includes("excluded_recipients__c")) cmp.set("v.excludedRecipientsDefault", commsRec[i]);
             }
        } else if(eventParams.changeType === "ERROR") {
            console.log(cmp.get("v.recordError"));
        }
    }

})