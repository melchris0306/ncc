import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from "lightning/uiRecordApi";

import ID_FIELD from '@salesforce/schema/Session__c.Id'
import SEND_INVITE_CHECKBOX_FIELD from '@salesforce/schema/Session__c.Send_Updated_Calendar_Invite__c'

export default class SessionParticipantSendCalendarUpdate extends LightningElement {
    
    @api recordId;

    isSuccess = true;
    toastTitle = '';
    toastMessage = '';
    toastVariant = '';

    @api invoke() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[SEND_INVITE_CHECKBOX_FIELD.fieldApiName] = true;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                console.log('@@@@ SUCCESS');
                console.log(recordInput);
                this.toastTitle = 'Success';
                this.toastMessage = 'Updated Calendar Invites have been Sent.';
                this.toastVariant = 'success';
            })
            .catch(error => {
                console.log('@@@@ ERROR');
                this.isSuccess = false;
                this.toastTitle = 'Error';
                this.toastMessage = 'An Error has occured. Please contact your Administrator.';
                this.toastVariant = 'error';
            })
            .finally(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.toastTitle, 
                        message: this.toastMessage, 
                        variant: this.toastVariant
                    })
                )
            });
    }
}