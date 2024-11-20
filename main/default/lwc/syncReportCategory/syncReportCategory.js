import { LightningElement, api } from 'lwc';

import getRecords from '@salesforce/apex/reportCategory.getRecords';
import updReportCategory from '@salesforce/apex/reportCategory.updReportCategory';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { updateRecord } from 'lightning/uiRecordApi';

export default class SyncReportCategory extends LightningElement 
{
    @api recordId;
    syncReport;
    reportCategories;
    isLoading = false;
    error;
    data;

    connectedCallback()
    {
        console.log('connectedCallback: recordId' + this.recordId);
        this.getSyncRecords();
    }

    syncRecords() 
    {   
        console.log('syncRecords ==>');
        this.isLoading = true;
        //alert(this.isLoading);
        updReportCategory({recordId: this.recordId})
            .then((result) => {
                this.error = undefined;
                //alert('Done update');
                this.isLoading = false;
                this.getSyncRecords();

                const event = new ShowToastEvent({
                    "title": "Success!",
                    "message": "Record Sync Successfully..."
                });

                this.dispatchEvent(event);

            })
            .catch((error) => {
                this.error = error;
                alert(error);
            });
        
    }

    getSyncRecords() 
    {
        this.syncReport = false;
        getRecords({ recordId: this.recordId })
            .then(result => {
                console.log('getRecords ==> Json Result: ' + JSON.stringify(result));
                var tempRecord = JSON.parse(JSON.stringify(result));
                this.syncReport =  tempRecord.syncReport;
                this.reportCategories =  tempRecord.reportCategories;
                this.error = undefined;
                console.log('connectedCallback: syncReport' + this.syncReport);
            })
            .catch(error => {
                console.log('getRecords ==> Json Error: ' + JSON.stringify(error));
                this.error = error;
                this.data = undefined;
            });
        
    }
}