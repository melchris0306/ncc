import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getAllAgileRaids from '@salesforce/apex/AgileRaidsListViewController.getAllAgileRaids'

export default class AgileRaidsListView extends NavigationMixin(LightningElement)  {
    @track mydata;
    @track error;
    @api recId;
    @track sObjectName = 'Agile_RAID__c';
    @track mycolumns = [
        {label: 'UID',fieldName: 'nameUrl',type: 'url',typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
        {label:'Description',fieldName:'Description',type:'textarea'},
        {label:'Resolution',fieldName:'Resolution',type:'textarea'},
        {label:'Type',fieldName:'Type',type:'picklist'},
        {label:'Priority',fieldName:'Priority',type:'picklist'},
        {label:'Status',fieldName:'Status',type:'picklist'},
        {label:'Target Resolution Date',fieldName:'TargetResolutionDate',type:'date'},
        {label:'Owner Name',fieldName:'OwnerName',type:'string'},
        {type:'action',typeAttributes:{rowActions:[{label:'View',name:'view'},{label:'Edit',name:'edit'}]}}
    ];

    @track wiredData;

    @wire(getAllAgileRaids,({recordId : '$recId'}))
    wiredAccounts(result){
        this.wiredData = this.result;
        if(result.data){
            let d = [];
            result.data.forEach(e => {
                let rec = {};
                rec.Id = e.Id;
                rec.nameUrl = '/'+e.Id;
                rec.Name = e.Name;
                rec.Description = e.Description__c;
                rec.Resolution = e.Resolution__c;
                rec.Type = e.Type__c;
                rec.Priority = e.Priority__c;
                rec.Status = e.Status__c;
                rec.TargetResolutionDate = e.Target_Resolution_Date__c;
                rec.OwnerName = e.Owner.Name ;
                d.push(rec);
            });

            this.mydata = d;
            this.error = undefined;
        }else if(result.error){
            this.error = 'Unknown error';
            if (Array.isArray(result.error.body)) {
                this.error = result.error.body.map(e => e.message).join(', ');
            } else if (typeof result.error.body.message === 'string') {
                this.error = result.error.body.message;
            }
            this.record = undefined;
        }
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

    handleRowAction(e) {

        const actionName = e.detail.action.name;
        const row = e.detail.row;
        console.log('handleRowAction = '+ JSON.stringify(row));
        switch ( actionName ) {
            case 'view':
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        actionName: 'view',
                    },
                }).then(url => {
                    window.open(url);
                });
                break;
            case 'edit':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        objectApiName: this.sObjectName,
                        actionName: 'edit'
                    }
                });
                break;
            default:
        }

    }

    refreshComponent(){
        console.log('refresh component');
        return refreshApex(this.wiredData);
    }
   
}