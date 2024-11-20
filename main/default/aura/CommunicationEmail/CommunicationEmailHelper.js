({  
    // 5/16/2021 - 01102 - Ability to Save as Draft for Communications
    initializeDraftEmail : function(cmp, event, helper){
        const action = cmp.get('c.initializeDraftEmail');
        action.setParams({ recordId : cmp.get('v.recordId') });
        action.setCallback(this, function(response){
            const state = response.getState();
            if(state === 'SUCCESS'){
                //const communicationEmail = response.getReturnValue();
                const communicationEmail = helper.cleanUpNamespace(response.getReturnValue());
                if(communicationEmail){

                    //Updated by XenReyes Oct282022 CCN-814
                    //console.log('This is an edit draft');

                    cmp.set('v.communication', communicationEmail.communication);
                    cmp.set('v.contactIdList', communicationEmail.contactRecipientIds.length ? communicationEmail.contactRecipientIds : [] );

                    //CCN-1004 Xen Reyes January 25, 2022
                    cmp.set('v.contactIdListCC', communicationEmail.contactRecipientIdsCC.length ? communicationEmail.contactRecipientIdsCC : [] );
                    cmp.set('v.contactIdListBCC', communicationEmail.contactRecipientIdsBCC.length ? communicationEmail.contactRecipientIdsBCC : [] );

                    /* cmp.set('v.ccRecipients', communicationEmail.communication.Email_Recipient_CC__c ? communicationEmail.communication.Email_Recipient_CC__c : []);
                    cmp.set('v.bccRecipients', communicationEmail.communication.Email_Recipient_BCC__c ? communicationEmail.communication.Email_Recipient_BCC__c : []); */

                    if(communicationEmail.communication.Organization_Wide_Email_Id__c ){
                        helper.getOrgWideEmailAddress(cmp, event, helper, communicationEmail.communication.Organization_Wide_Email_Id__c);
                    }
                    else{
                        cmp.set('v.isLoading', false);
                    }
                }
                else{

                    //Updated by XenReyes Oct282022 CCN-814
                    console.log('This is a new draft');
                    cmp.set('v.isLoading', false);
                }
            }
            else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        $A.enqueueAction(action);
    },

    getCurrentUser : function(cmp, event, helper){
		const action = cmp.get("c.getCurrentUser");
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
                const returnValue = response.getReturnValue();
                cmp.set('v.user', returnValue);
            }
            else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        $A.enqueueAction(action);
    },

    //Updated by XenReyes Nov222021 CCN-814
    //CCN-COM-1214-DV XEN REYES Apr. 14, 2022
    getRecordSobject : function(cmp, event, helper){
		const action = cmp.get("c.getRecordSobject");
        action.setParams({ recordId : cmp.get('v.recordId') });
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
                let returnValue = response.getReturnValue();
                returnValue = returnValue.toLowerCase();
                cmp.set('v.sobjectType', returnValue);

                if(returnValue.includes('communication__c')){

                    //XenReyes CCN-2251 Nov2022
                    const getNamespace = cmp.get("c.getNamespacePrefix");
                    getNamespace.setCallback(this, function(response) {
                        const state = response.getState();
                        if(state === "SUCCESS"){
                            var ns = response.getReturnValue(), fieldList = [];
                            cmp.get("v.commsFields").forEach(x => fieldList.push(ns + x));
                            cmp.set('v.commsFields', fieldList);
                            cmp.set('v.isCommunication', true);
                        } else{
                            helper.showToastError(helper.logError(response.getError()));
                        }
                    });
                    $A.enqueueAction(getNamespace);

                    const getAttachments = cmp.get("c.getAttachmentRecordsCommunication");
                    getAttachments.setParams({ recordId : cmp.get('v.recordId') });
                    getAttachments.setCallback(this, function(response) {
                        const state = response.getState();
                        if(state === "SUCCESS"){
                            const returnValue = response.getReturnValue();
                            let listFiles = [];
                            for (let i = 0; i < returnValue.length; i++) {
                                let varFiles = {    name : returnValue[i].ContentDocument.Title + '.' + returnValue[i].ContentDocument.FileExtension,
                                                    documentId : returnValue[i].ContentDocumentId};
                                listFiles.push(varFiles);
                            }
                            cmp.set('v.attachmentRecords', listFiles);
                        } else{
                            helper.showToastError(helper.logError(response.getError()));
                        }
                    });
                    $A.enqueueAction(getAttachments);

                } else if(returnValue.includes('journey__c')){
                    cmp.set('v.isFromJourney', true)
                }
            }
            else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        $A.enqueueAction(action);
    },

    validateInputs : function(cmp, event, helper){
        const communication = cmp.get('v.communication');
        let ccRecipients = cmp.get('v.ccRecipients');
        let bccRecipients = cmp.get('v.bccRecipients');
        let currentIndex = cmp.get('v.currentPageIndex');
        let lastPageIndex = cmp.get('v.lastPageIndex');
        const contactIdList = cmp.get('v.contactIdList');

        if(currentIndex === 1){
            let hasError = true;
            if(!communication.Name){
                helper.showToastWarning('Communication Name is Required');
            }
            else if(!communication.Subject__c){
                helper.showToastWarning('Subject is Required');
            }
            else if(!communication.Body__c){
                helper.showToastWarning('Email Body/Message is Required. Please select an Email Template.');
            }
            else if(communication.Email_Delivery_Date_Time_Schedule__c){
                //checks date and time against system date/time
                const action = cmp.get('c.checkEmailScheduleDateTime');
                action.setParams({communicationSchedule : communication.Email_Delivery_Date_Time_Schedule__c.toString().replace("T", " ")});
                action.setCallback(this, function(response){
                    const state = response.getState();

                    if(state === 'SUCCESS'){
                        const returnValue = response.getReturnValue();

                        if (returnValue && returnValue.length){
                            helper.showToastWarning(returnValue);
                        } else {
                            cmp.set('v.currentPageIndex', currentIndex <= lastPageIndex-1 ? ++currentIndex : currentIndex);
                        }
                    }
                });

                $A.enqueueAction(action);
                
            } else {
                hasError = false;
            }

            if (!hasError){
                cmp.set('v.currentPageIndex', currentIndex <= lastPageIndex-1 ? ++currentIndex : currentIndex);
            }
        }
        else if(currentIndex === 2){
            if(!contactIdList.length){
                helper.showToastWarning('Contact Recipient is required!');
            }
            else{
                if(ccRecipients.length) communication.Email_Recipient_CC__c = ccRecipients.join();
                if(bccRecipients.length) communication.Email_Recipient_BCC__c = bccRecipients.join();
                cmp.set('v.currentPageIndex', currentIndex <= lastPageIndex-1 ? ++currentIndex : currentIndex);
            }
        }
    },
    
    // 5/16/2021 - 01102 - Ability to Save as Draft for Communications
    saveDraft : function(cmp, event, helper){
        cmp.set('v.isLoading', true);
        const communicationEmailPayload = helper.createCommunicationEmailPayload(cmp, event, helper, true);
        const action = cmp.get('c.saveDraft');
        action.setParams({ communicationEmailPayload });
        action.setCallback(this, function(response){
            const state = response.getState();
            if(state === 'SUCCESS'){
                const returnValue = response.getReturnValue();
                //Updated by XenReyes Oct282022 CCN-814
                //console.log('Apex Successfully Invoked!');
                if(returnValue){
                    helper.showToastError(helper.logError(returnValue));
                    cmp.set('v.isLoading', false);
                }
                else{
                    helper.showSuccessToast($A.get('$Label.c.Communication_Success_Save_Draft'));
                    $A.get('e.force:refreshView').fire();
                    helper.closeModal();
                }
            }
            else{
                helper.showToastError(helper.logError(response.getError()));
                cmp.set('v.isLoading', false);
            }
        });
        $A.enqueueAction(action);
    },

    setupEmailBody : function(cmp, event, helper){
        let communication = cmp.get('v.communication');
        if(communication.Body__c && (!communication.Body__c.includes('<html') && !communication.Body__c.includes('<table'))){
            let email = communication.Body__c;
            email = email.replaceAll('<p><br></p>', '<br/>');
            email = email.replaceAll('<p>', '<span>');
            email = email.replaceAll('</p>', '</span><br/>');
            communication.Body__c = email;
            cmp.set('v.communication', communication);
            
            //Updated by XenReyes Oct282022 CCN-814
            //console.log('Email Body', communication.Body__c);
        }
    },
    
    sendCompassEmail : function(cmp, event, helper) {
        const communication = cmp.get('v.communication');
        // set status to outbox everytime the user click send
        communication.Status__c = 'Outbox';
        let isDraft = communication.Id ? true : false;
        const today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        if(!communication.Email_Date__c && !isDraft){
            communication.Email_Date__c = today;
            cmp.set('v.communication', communication);
        }
        cmp.set('v.isLoading', true);
        const communicationEmailPayload = helper.createCommunicationEmailPayload(cmp, event, helper, isDraft);
        let action = cmp.get('c.sendCompassEmail');
        action.setParams({ communicationEmailPayload });
        action.setCallback(this, function(response){
            const state = response.getState();
            if(state === 'SUCCESS'){
                const returnValue = response.getReturnValue();
                
                if(returnValue.length && returnValue != "EmailScheduled"){
                    helper.showToastError(helper.logError(returnValue));
                    cmp.set('v.isLoading', false);
                } 
                else if (returnValue == "EmailScheduled") {
                    helper.showSuccessToast($A.get('$Label.c.Communication_Success_Scheduled'));
                    $A.get('e.force:refreshView').fire();
                    helper.closeModal();
                }
                else{
                    helper.showSuccessToast($A.get('$Label.c.Communication_Success'));
                    $A.get('e.force:refreshView').fire();
                    helper.closeModal();
                }
            }
            else{
                helper.showToastError(helper.logError(response.getError()));
                cmp.set('v.isLoading', false);
            }
        })
        $A.enqueueAction(action);
	},

    // 5/16/2021 - 01102 - Ability to Save as Draft for Communications
    getOrgWideEmailAddress : function(cmp, event, helper, OrgWideEmailAddressId){
        const action = cmp.get('c.getOrgWideEmailAddressById');
        action.setParams({ OrgWideEmailAddressId });
        action.setCallback(this, function(response){
            const state = response.getState();
            if(state === 'SUCCESS'){
                const orgWideEmailAddressRecord = response.getReturnValue();
                cmp.set('v.orgWideEmailAddressRecord', orgWideEmailAddressRecord);
                cmp.set('v.isLoading', false);
            }
            else{
                helper.showToastError(helper.logError(response.getError()));
                cmp.set('v.isLoading', false);
            }
        });
        $A.enqueueAction(action);
    },

    // 5/16/2021 - 01102 - Ability to Save as Draft for Communications
    createCommunicationEmailPayload : function(cmp, event, helper, isDraft){
        const recordId = cmp.get('v.recordId') ? cmp.get('v.recordId') : null;
        const communication = cmp.get('v.communication') ? cmp.get('v.communication') : null;
        var contactRecipientIds = cmp.get('v.contactIdList').length ? cmp.get('v.contactIdList') : null;
        var contactRecipientsToBeRemoved = cmp.get('v.contactRecipientsToBeRemoved').length ? cmp.get('v.contactRecipientsToBeRemoved') : null;

        //Updated by XenReyes Oct282022 CCN-814
        //GET ALL CONTENT DOCUMENT IDS OF ATTACHED FILES
        let attachmentsList = [];
        var consolidatedFiles = cmp.get('v.attachmentRecords');
        if(!$A.util.isEmpty(consolidatedFiles)){
            for (let i = 0; i < consolidatedFiles.length; i++) {
                attachmentsList.push(consolidatedFiles[i].documentId);
            }
        }

        //CCN-1004 Xen Reyes January 25, 2022
        const contactRecipientIdsCC = cmp.get('v.contactIdListCC').length ? cmp.get('v.contactIdListCC') : null;
        const contactRecipientIdsBCC = cmp.get('v.contactIdListBCC').length ? cmp.get('v.contactIdListBCC') : null;
        const contactRecipientsToBeRemovedCC = cmp.get('v.contactRecipientsToBeRemovedCC').length ? cmp.get('v.contactRecipientsToBeRemovedCC') : null;
        const contactRecipientsToBeRemovedBCC = cmp.get('v.contactRecipientsToBeRemovedBCC').length ? cmp.get('v.contactRecipientsToBeRemovedBCC') : null;

        //passing a date/time in apex should not have a T in the string
        const emailSchedule = communication.Email_Delivery_Date_Time_Schedule__c ? communication.Email_Delivery_Date_Time_Schedule__c.replace("T", " ") : "";
        // communication.Email_Delivery_Date_Time_Schedule__c = emailSchedule;

        //Add properties with namespaces
        for (var key in communication) {
            if (Object.prototype.hasOwnProperty.call(communication, key)) {
                //XenReyes CCN-2251 Nov2022
                if(key.includes('__c') && !key.includes('compass_cn__') && !key.includes('beta_ccn__')){
                    communication['compass_cn__' + key] = communication[key];
                    communication['beta_ccn__' + key] = communication[key];
                }
            }
        }

        //CCN-COM-1214-DV XEN REYES Apr. 14, 2022, CCN-2251 Nov2022
        //Exclude/Remove recipients only when send, not when draft
        var excludedRecipients = '';
        if((cmp.get('v.isFromJourney') || cmp.get('v.isCommunicationHasJourney')) && cmp.get('v.excludedIds') !== undefined) {
            var excludedOptions = [], includedOptions = [], options = cmp.get('v.options'), excludedIds = cmp.get('v.excludedIds'), contactRecipientsToBeRemovedTemp = [];

            for(let x of options){
                if(excludedIds != undefined){ //CCN-2861 XEN REYES Apr. 14, 2023
                    if(excludedIds.includes(x.value)) {
                        excludedOptions.push(x); 
                        if(cmp.get("v.isSend")){
                            contactRecipientsToBeRemovedTemp.push(x.value);
                            const index = contactRecipientIds.indexOf(x.value);
                            if (index > -1) contactRecipientIds.splice(index, 1);
                        }
                    }
                }
                includedOptions.push(x);
            }
            contactRecipientsToBeRemoved === null ? contactRecipientsToBeRemoved = contactRecipientsToBeRemovedTemp : contactRecipientsToBeRemoved = contactRecipientsToBeRemoved.concat(contactRecipientsToBeRemovedTemp);
            excludedRecipients = JSON.stringify(excludedOptions);
        }
        
        const payload = {
            recordId,   
            communication,
            emailSchedule,
            contactRecipientIds,
            contactRecipientsToBeRemoved,
            isDraft,
            attachmentsList,

            //CCN-1004 Xen Reyes January 25, 2022
            contactRecipientIdsCC,
            contactRecipientIdsBCC,
            contactRecipientsToBeRemovedCC,
            contactRecipientsToBeRemovedBCC,

            //CCN-COM-1214-DV XEN REYES Apr. 14, 2022
            excludedRecipients
        };

        const communicationEmailPayload = JSON.stringify(payload);
        //console.log('communicationEmailPayload: ', communicationEmailPayload);
        return communicationEmailPayload;
    },

    showSuccessToast : function(message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "type" : "success",
            "message": message
        });
        toastEvent.fire();
    },

    showToastError : function(message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "type" : "error",
            "message": message
        });
        toastEvent.fire();
    },

    showToastWarning : function(message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Field Required!",
            "type" : "warning",
            "message": message
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

    //Updated by XenReyes Oct282022 CCN-814
    deleteFilesCloseModal : function(cmp, helper){
        
        //XenReyes CCN-2251 Nov2022
        if(!cmp.get('v.sobjectType').includes('communication__c')){
            let attachmentsList = cmp.get("v.attachmentRecords");
            if(!$A.util.isEmpty(attachmentsList)){
                cmp.set("v.isLoading", true);

                let idArray = [];
                for (let i = 0; i < attachmentsList.length; i++) {
                    idArray.push(attachmentsList[i].documentId); 
                }

                const action = cmp.get("c.deleteFile");
                action.setParams({ idList : idArray });
                action.setCallback(this, function(response) {
                    const state = response.getState();
                    if(state === "SUCCESS"){
                        $A.get("e.force:closeQuickAction").fire();
                    } else {
                        helper.showToastError(helper.logError(response.getError()));
                    }
                    cmp.set("v.isLoading", false);
                });
                $A.enqueueAction(action);
            } else {
                $A.get("e.force:closeQuickAction").fire();
            }
        } else {
            $A.get("e.force:closeQuickAction").fire();
        }
    },

    closeModal : function(){
        $A.get("e.force:closeQuickAction").fire();
    },
            
    cleanUpNamespace : function(jsonData){
        let responseStr = JSON.stringify(jsonData);
        
        if(responseStr.includes('beta_ccn__')){
            responseStr = responseStr.replaceAll('beta_ccn__', '');
        }
        if(responseStr.includes('compass_cn__') ){
            responseStr = responseStr.replaceAll('compass_cn__', '');
        }

        return JSON.parse(responseStr);
    }

})