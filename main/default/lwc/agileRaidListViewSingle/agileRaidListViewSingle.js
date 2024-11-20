import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAgileRaidsData from '@salesforce/apex/AgileRaidsListViewController.getAgileRaidsData'
import getAgileRaidsCount from '@salesforce/apex/AgileRaidsListViewController.getAgileRaidsCount'

export default class AgileRaidListViewSingle extends NavigationMixin(LightningElement) {
    @api recordId;
    @track error;
    @track record;
    @track recordCount;
    @track Title = 'Agile RAID²';
    @track sObjectName = 'Agile_RAID__c';

    @wire(getAgileRaidsData,({recordId : '$recordId'}))
    wiredRecords({error, data}){
        
        if (data) {
            let rows = [];
            let tempRows = JSON.parse( JSON.stringify( data ) );

            for ( let i = 0; i < tempRows.length; i++ ) {

                let row =  tempRows[ i ];
                row.conName = "/" + row[ "Id" ];
                rows.push( row );
                
            }

            this.record = rows;
            this.error = undefined; 
        } else if (error) {
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            this.record = undefined;
        }
    }

    @wire(getAgileRaidsCount,({recordId : '$recordId'}))
    wiredRecordsCount({error, data}){
        if (data) {
            this.recordCount = data;
            this.Title = 'Agile RAID² (' + data + ')';
            this.error = undefined;
        } else if (error) {
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            this.record = undefined;
        }
    }

    handleNavigate(event) {
        event.preventDefault();
        let componentDef = {
            componentDef: "c:agileRaidsListView",
            attributes: {
                recId: this.recordId
            }
        };
        
        let encodedComponentDef = btoa(JSON.stringify(componentDef));
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/one/one.app#' + encodedComponentDef
            }
        });
    }

    createNew() {

        this[NavigationMixin.Navigate]({            
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.sObjectName,
                actionName: 'new'                
            }
        });

    }

}