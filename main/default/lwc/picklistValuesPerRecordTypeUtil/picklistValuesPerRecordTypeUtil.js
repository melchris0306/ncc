import { LightningElement, api, wire } from 'lwc';

//importing record ui api service for getting api that supports retrieving object info 
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

export default class getObjPicklistDetails extends LightningElement {

    @api objApiName;
    @api objRecordTypeId;

    @wire(getPicklistValuesByRecordType, { objectApiName: '$objApiName', recordTypeId: '$objRecordTypeId' })
    picklistInfoData({ error, data }) {
        if (error) {
            console.log(JSON.stringify(error));
        }

        if (data) {
            const pickListDataEvent = new CustomEvent('picklistDataReceive', {
                detail: { picklistData: data }
            });

            this.dispatchEvent(pickListDataEvent);
        }
    }
}