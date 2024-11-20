({
    initializeEmailTemplate : function(cmp, event, helper){
        let initialLookupIds = [];
        const communication = cmp.get('v.communication');
        if(communication.Email_Template_Id__c){
            initialLookupIds.push(communication.Email_Template_Id__c);
            const action = cmp.get("c.getTemplateLookupById");
            action.setParams({ initialLookupIds });
            action.setCallback(this, function(response) {
                const state = response.getState();
                if(state === "SUCCESS"){
                    cmp.set('v.selectedEmailTemplate', response.getReturnValue());
                    helper.setInitialTemplate(cmp, event, helper, communication);
                } else {
                    helper.showToastError(helper.logError(response.getError()));
                }
            });
            $A.enqueueAction(action);	
        }
    },

    setInitialTemplate : function(cmp, event, helper, communication){
        const action = cmp.get("c.getEmailTemplate");
        action.setParams({ id : communication.Email_Template_Id__c })
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
                const emailTemplate = response.getReturnValue();
                communication.Body__c = emailTemplate.renderedHtml;
                cmp.set('v.communication', communication);
            }else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        $A.enqueueAction(action);
    },

    initializeEmailOptions : function(cmp, event, helper){
        let orgWideEmailList = cmp.get('v.orgWideEmailList');
        if(!orgWideEmailList.length){
            helper.getOrgWideEmailAddresses(cmp, event, helper);
        }
        else{
            orgWideEmailList = cmp.get('v.orgWideEmailList');
            helper.initializeSelectedEmails(cmp, event, helper, orgWideEmailList);
        }
    },

    initializeSelectedEmails : function(cmp, event, helper, orgWideEmailList){
        let communication = cmp.get('v.communication');
        let user = cmp.get('v.user');
        let selectedSender = cmp.get('v.selectedSender');
        let selectedReplyReceiver = cmp.get('v.selectedReplyReceiver');
        const orgWideEmailAddressOptions = cmp.get('v.orgWideEmailAddressOptions');

        if(!selectedSender){
            if(communication.Sender_Email_Address__c === user.Email){
                cmp.set('v.selectedSender', communication.Sender_Email_Address__c);
            }
            else if(communication.Organization_Wide_Email_Id__c){
                cmp.set('v.selectedSender', communication.Organization_Wide_Email_Id__c);
            }
            else{
                helper.setDefaultSender(cmp, event, helper, orgWideEmailList);
            }
        }


        if(!selectedReplyReceiver && communication.Reply_Email_Address__c && orgWideEmailAddressOptions){
            selectedReplyReceiver = _.find(orgWideEmailAddressOptions, function(item){
                return item.label.includes(communication.Reply_Email_Address__c);
            });
            cmp.set('v.selectedReplyReceiver', selectedReplyReceiver.value);
        }
        cmp.set('v.isReplyReceiverDisabled', selectedReplyReceiver ? false : true);
        cmp.set('v.isLoading', false);
    },

	getOrgWideEmailAddresses : function(cmp, event, helper) {
        const user = cmp.get('v.user');
		const action = cmp.get("c.getOrgWideEmailAddresses");
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
                const returnValue = response.getReturnValue();
                let options = _.map(returnValue, function(item){
                    return { label : item.DisplayName + ' <' + item.Address + '>', value : item.Id};
                });
                options.unshift({ label: `My Email <${user.Email}>`, value : user.Email });
                cmp.set('v.orgWideEmailAddressOptions', options);
                cmp.set('v.orgWideEmailList', returnValue);

                helper.initializeSelectedEmails(cmp, event, helper, returnValue);
            }else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        $A.enqueueAction(action);
	},

    setDefaultSender : function(cmp, event, helper, orgWideEmailList) {
		const action = cmp.get("c.getDefaultSenderId");
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
                let returnValue = response.getReturnValue();
                cmp.set('v.selectedSender', returnValue);
                let selectedOrgWideEmail = _.find(orgWideEmailList, function(item){
                    return item.Id === returnValue;
                });
               
                cmp.set('v.orgWideEmailAddressRecord', selectedOrgWideEmail);
                let communication = cmp.get('v.communication');
                communication.Organization_Wide_Email_Id__c = selectedOrgWideEmail.Id;
                communication.Sender_Email_Address__c = selectedOrgWideEmail.Address;
                communication.Sender_Name__c = selectedOrgWideEmail.DisplayName;
                cmp.set('v.communication', communication);
            }else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        $A.enqueueAction(action);
	},

    changeSender: function(cmp, event, helper){
        const user = cmp.get('v.user');
        let communication = cmp.get('v.communication');
        let selected = event.getParam('value');
        let selectedOrgWideEmail = _.find(cmp.get('v.orgWideEmailList'), function(item){
            return item.Id === selected;
        });
        
        if(selectedOrgWideEmail){
            cmp.set('v.orgWideEmailAddressRecord', selectedOrgWideEmail);
            cmp.set('v.selectedSender', selectedOrgWideEmail.Id);
            communication.Organization_Wide_Email_Id__c = selectedOrgWideEmail.Id;
            communication.Sender_Email_Address__c = selectedOrgWideEmail.Address;
            communication.Sender_Name__c = selectedOrgWideEmail.DisplayName;
        }
        else if(selected === user.Email){
            cmp.set('v.selectedSender', user.Email);
            communication.Organization_Wide_Email_Id__c = null;
            communication.Sender_Email_Address__c = user.Email;
            communication.Sender_Name__c = user.Name;
        }
        else{
            cmp.set('v.orgWideEmailAddressRecord', null);
            cmp.set('v.selectedSender', '');
        }
      
        cmp.set('v.communication', communication);
        // console.log('Selected OrgWideEmailAddress > ', selectedOrgWideEmail);
    },

    changeReplyReceiver : function(cmp, event, helper){
        const user = cmp.get('v.user');
        let communication = cmp.get('v.communication');
        let selected = event.getParam('value');
        let selectedReplyReceiver = _.find(cmp.get('v.orgWideEmailList'), function(item){
            return item.Id === selected;
        });
        if(selectedReplyReceiver){
            cmp.set('v.selectedReplyReceiver', selectedReplyReceiver.Id);
            // cmp.set('v.replyEmailAddress', selectedReplyReceiver);
            communication.Reply_Email_Address__c = selectedReplyReceiver.Address;
        }
        else if(selected === user.Email){
            cmp.set('v.selectedReplyReceiver', user.Email);
            communication.Reply_Email_Address__c = user.Email;
        }
        else{
            cmp.set('v.selectedReplyReceiver', null);
            communication.Reply_Email_Address__c = null;
        }
        cmp.set('v.communication', communication);
    },

    changeEmailTemplate : function(cmp, event, helper){
        try{
            let communication = cmp.get('v.communication');
            const lookupElement = cmp.find('templateLookup').getElement();
            const selection = lookupElement.getSelection();
            cmp.set('v.selectedEmailTemplate', selection);
            communication.Email_Template_Id__c = selection[0].id;
            helper.getEmailTemplate(cmp, event, helper, communication);
        } catch(e) {
            console.log('Error', e);
        }
    },
    
    getEmailTemplate : function(cmp, event, helper, communication){
        const action = cmp.get("c.getEmailTemplate");
        action.setParams({ id : communication.Email_Template_Id__c })
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
                const emailTemplate = response.getReturnValue();
                communication.Subject__c = emailTemplate.subject;
                communication.Body__c = emailTemplate.renderedHtml;
                cmp.set('v.communication', communication);
            }else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        $A.enqueueAction(action);
    },

    showToastError : function(error) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "type" : "error",
            "message": error
        });
        toastEvent.fire();
    },
    
    logError : function(errors){
        if (errors) {
            if (errors[0] && errors[0].message) {
                // log the error passed in to AuraHandledException
                let errorMessage = "Error message: " + errors[0].message
                console.log(errorMessage);
                return errorMessage;
            }
            else{
                console.log("Unknown error", JSON.stringify(errors));
                return "Unknown error", JSON.stringify(errors);
            }
        } else {
        	console.log("Unknown error", JSON.stringify(errors));
            return "Unknown error", JSON.stringify(errors);
        }
	},

    getTemplateSearchResults : function(cmp, event, helper) {
        const lwcLookup = cmp.find('templateLookup').getElement();
        let keyword = event.getParam('searchTerm');
        let idList = event.getParam('selectedIds');
        const action = cmp.get("c.searchEmailTemplate");
        action.setParams({ searchTerm : keyword, selectedIds : idList });
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
                const returnValue = response.getReturnValue();
                // get a reference of the LWC lookup element and use the lookup's setSearchResults
                // to set Search Results based on the keyword
                lwcLookup.setSearchResults(returnValue);
            }else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        
        $A.enqueueAction(action);	
    },

    //Updated by XenReyes Oct282022 CCN-814
    deleteFile : function(cmp, event, helper){
        cmp.set("v.isLoading", true);

        var targetId = event.target.id;
        let idArray = [];
        idArray.push(targetId);

        const action = cmp.get("c.deleteFile");
        action.setParams({ idList : idArray });
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
 
                //Remove the file in attachmentRecords, and send to event so it can be deleted when the modal is closed.
                let consolidatedFiles = cmp.get("v.attachmentRecords");
                for (let i = 0; i < consolidatedFiles.length; i++) {
                    if(consolidatedFiles[i].documentId === targetId){
                        const index = i;
                        if (index > -1) {
                            consolidatedFiles.splice(index, 1);
                        }
                    }
                }
                cmp.set("v.attachmentRecords", consolidatedFiles);

                let eventVar = cmp.getEvent("commsEvent");
                eventVar.setParams({ 
                    "attachmentsList" : consolidatedFiles
                });
                eventVar.fire();
                
            } else {
                helper.showToastError(helper.logError(response.getError()));
            }
            cmp.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },

    //Updated by XenReyes Oct282022 CCN-814
    getUploadedFiles : function(cmp, event, helper){
        let uploadedFiles = event.getParam("files");
        let consolidatedFiles = cmp.get("v.attachmentRecords");

        consolidatedFiles.push.apply(consolidatedFiles, uploadedFiles);
        cmp.set("v.attachmentRecords", consolidatedFiles);

        let eventVar = cmp.getEvent("commsEvent");
        eventVar.setParams({ 
            "attachmentsList" : consolidatedFiles
        });
        eventVar.fire();
    }

})