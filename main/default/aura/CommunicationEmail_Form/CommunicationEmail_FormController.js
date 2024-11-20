({
    afterScriptsLoaded : function(cmp, event, helper){
        helper.initializeEmailOptions(cmp, event, helper);
        helper.initializeEmailTemplate(cmp, event, helper);
	},
    
    handleSenderChange : function(cmp, event, helper){
        helper.changeSender(cmp, event, helper);
    },
    
    handleSubjectChange : function(cmp, event, helper){
        let communication = cmp.get('v.communication');
        communication.Subject__c = event.getParam('value');
        cmp.set('v.communication', communication);
    },

    handleReplyReceiverChange : function(cmp, event, helper){
        helper.changeReplyReceiver(cmp, event, helper);
    },

    handleCommunicationNameChange : function(cmp, event, helper){
        let communication = cmp.get('v.communication');
        communication.Name = event.getParam('value');
        cmp.set('v.communication', communication);
    },
    
    handleEmailDateChange : function(cmp, event, helper){
        let communication = cmp.get('v.communication');
        communication.Email_Date__c = event.getParam('value');
        cmp.set('v.communication', communication);
    },
    
    handleMilestoneChange : function(cmp, event, helper){
        let communication = cmp.get('v.communication');
        communication.Milestone__c = event.getParam('checked');
        cmp.set('v.communication', communication);
    },

    toggleReplyReceiver : function(cmp, event, helper){
        let communication = cmp.get('v.communication');
        let isReplyReceiverDisabled = cmp.get('v.isReplyReceiverDisabled');
        cmp.set('v.isReplyReceiverDisabled', !isReplyReceiverDisabled);
        cmp.set('v.selectedReplyReceiver', null);
        communication.Reply_Email_Address__c = null;
        cmp.set('v.communication', communication);
        // cmp.set('v.replyEmailAddress', null);
    },

    handleTemplateSearch : function(cmp, event, helper){
        helper.getTemplateSearchResults(cmp, event, helper);
    },

    handleTemplateChange : function(cmp, event, helper){
        helper.changeEmailTemplate(cmp, event, helper);
    },

    //Updated by XenReyes Oct282022 CCN-814
    handleUploadFinished : function(cmp, event, helper){
        helper.getUploadedFiles(cmp, event, helper);
    },

    //Updated by XenReyes Oct282022 CCN-814
    handledeleteAttachment : function(cmp, event, helper){
        helper.deleteFile(cmp, event, helper);
    },
})