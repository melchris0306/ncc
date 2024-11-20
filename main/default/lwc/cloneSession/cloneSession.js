/**
 * @description       : [CCN-EVE-1244-DV] cloneSession LWC
 * @author            : adavid@ulapp.co
 * @group             : 
 * @last modified on  : 04-04-2022
 * @last modified by  : adavid@ulapp.co
 * @version     1.0     29-03-2022      Aaron David     [CCN-EVE-1244-DV] Initial version.
**/

import { LightningElement, api } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { NavigationMixin } from 'lightning/navigation';
import cloneSesh from '@salesforce/apex/CloneSessionController.cloneSessionRecord';

export default class CloneSession extends NavigationMixin(LightningElement) {

    @api recordId;
    @api invoke() {
        this.startToast('Clone', 'Starting cloning process...', 'info');
        //Call the cloning imperative apex js method
        this.startCloning();
    }

    startCloning() {
        cloneSesh({ sessionId: this.recordId })
            .then(result => {
                this.startToast('Clone', 'Cloning Process Completed', 'success');
                console.log('Clones Session >>> ', result);
                this.navigateToRecord(result);
            })
            .catch(error => {
                this.startToast('Clone', 'An Error occured during cloning' + error, 'error');
            });
    }

    startToast(title, msg, variant) {
        let event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    navigateToRecord(clonedRecId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: clonedRecId,
                actionName: 'view',
            },
        });
    }
}