import { LightningElement, api, track, wire } from 'lwc';
import getData from '@salesforce/apex/CloneTestExecutionScreenController.getData';
import getTestExecutionsById from '@salesforce/apex/CloneTestExecutionScreenController.getTestExecutionsById';
import {
    FlowAttributeChangeEvent,
    FlowNavigationNextEvent,
} from 'lightning/flowSupport';
export default class CloneTestExecutionScreen extends LightningElement {
    @api availableActions = [];
    @api recordId;
    @track records;
    @track showTable = false;
    @track testingPhaseValues = [];
    @api step = "1";
    @api selectedIds = [];
    @api selectedRecords = [];

    @track massSelectedPhase;
    @track massSelectedAssignedTo;

    @track displayedRecords = [];

    @api recordsToClone = [];
    @api extraMessage = "";
    @api redirectId = "";
    @track noSelectedRows = true;
    @track columns = [
        { label: 'Name',
            fieldName: 'testExecutionUrl',
            type: 'url',
            typeAttributes: {label: { fieldName: 'Name' }, 
            target: '_blank'},
            sortable: false },
        { label: 'Epic',
            fieldName: 'epicUrl',
            type: 'url',
            typeAttributes: {label: { fieldName: 'epicName' }, 
            target: '_blank'},
            sortable: false },
        { label: 'Owner',
            fieldName: 'ownerUrl',
            type: 'url',
            typeAttributes: {label: { fieldName: 'ownerName' }, 
            target: '_blank'},
            sortable: false},
        { label: 'Testing Phase', fieldName: 'Testing_Phase__c'}
        
    ];

    get isStepOne(){
        return this.step == "1";
    }

    get isStepTwo(){
        return this.step == "2";
    }
    get isStepThree(){
        return this.step == "3";
    }

    retrieveData(){
        if(this.step == "1"){
            
           

            if(!this.records){
                 getData({
                recId : this.recordId
            })
            .then((result) => {
                this.records = result.testExeuctionRecords;
                for(let i=0; i<this.records.length; i++){
                    this.records[i]["testExecutionUrl"] = window.location.origin + "/" + this.records[i].Id;
                    this.records[i]["epicUrl"] = window.location.origin + "/" + this.records[i].Epic__c;
                    this.records[i]["epicName"] = this.records[i].Epic__r ? this.records[i].Epic__r.Name : '';
                    this.records[i]["ownerUrl"] = this.records[i].Assigned_To__r ? window.location.origin + "/" + this.records[i].Assigned_To__r.Name : "";
                    this.records[i]["ownerName"] = this.records[i].Assigned_To__r ?this.records[i].Assigned_To__r.Name : "";
                }
            
            this.testingPhaseValues = result.testingPhaseValues;
            this.showTable = true;
            })
            .catch((error) => {
                console.log(error);
            });
            }

             
        }
        
        if(this.step == "2"){
            let teSelectorId = "testExecutionSelectionTable";
            let element = this.template.querySelector('div[data-id="' + teSelectorId + '"]'); 
            element.style.display = "none";
            getTestExecutionsById({
                recordIds : this.selectedIds
            })
            .then((result) => {
                
                
                this.selectedRecords = result;
                this.recordsToClone = result;

                for(let i=0; i<this.selectedRecords.length; i++){
                    this.selectedRecords[i]["testExecutionUrl"] = window.location.origin + "/" + this.selectedRecords[i].Id;
                    this.selectedRecords[i]["epicUrl"] = window.location.origin + "/" + this.selectedRecords[i].Epic__c;
                    this.selectedRecords[i]["epicName"] = this.selectedRecords[i].Epic__r.Name;
                    this.selectedRecords[i]["ownerUrl"] = this.selectedRecords[i].Assigned_To__c ? window.location.origin + "/" + this.selectedRecords[i].Assigned_To__r.Name : "";
                    this.selectedRecords[i]["ownerName"] = this.selectedRecords[i].Assigned_To__r ?this.selectedRecords[i].Assigned_To__r.Name : "";
                    this.selectedRecords[i]["currentassignedtouser"] = this.selectedRecords[i].Assigned_To__r ?[{id: this.selectedRecords[i].Assigned_To__c, title: this.selectedRecords[i].Assigned_To__r.Name, subtitle: ""}] : "";
                }

                this.displayedRecords = this.selectedRecords;

                for(let i=0; i<this.recordsToClone.length; i++){
                    delete this.recordsToClone[i].Owner;
                    delete this.recordsToClone[i].Epic__r;
                    delete this.recordsToClone[i].Assigned_To__r;
                }
            
            this.showTable = true;

            let currentAssignedTo = this.massSelectedAssignedTo;
            for(let i=0; i<this.displayedRecords.length; i++){
                if(currentAssignedTo && currentAssignedTo.id){
                     this.displayedRecords[i].Assigned_To__c = currentAssignedTo.id;
                    this.displayedRecords[i].currentassignedtouser = [{id: currentAssignedTo.id, title: currentAssignedTo.title, subtitle: ""}];
                }
                if(this.massSelectedPhase){
                    this.displayedRecords[i]["Testing_Phase__c"] = this.massSelectedPhase;
                }
                
            }

            })
            .catch((error) => {
                console.log(error);
            });
        }
    }

    connectedCallback() {
        
        this.retrieveData();
            
    }

    handleSelected(event) {
        let currentAssignedTo = JSON.parse(JSON.stringify(event.detail[0]));
        for(let i=0; i<this.recordsToClone.length; i++){
            if(this.recordsToClone[i].Id == currentAssignedTo.parentid){
                this.recordsToClone[i].Assigned_To__c = currentAssignedTo.id;
                console.log(JSON.parse(JSON.stringify(this.recordsToClone[i])))
            }
        }
    }

    handleMassUserSelect(event) {
        let currentAssignedTo = JSON.parse(JSON.stringify(event.detail[0]));
        this.massSelectedAssignedTo = currentAssignedTo;
        
    }

    handleChange(event){
    let currentId = event.target.dataset.id;
    let selectedValue = event.detail.value;
    for(let i=0; i<this.recordsToClone.length; i++){
                if(this.recordsToClone[i].Id == currentId){
                    this.recordsToClone[i]["Testing_Phase__c"] = selectedValue;
                }
            }
    }

    handleMassPhaseSelect(event){
    let selectedValue = event.detail.value;
    this.massSelectedPhase = selectedValue;
    
    }

    onRowsSelection(event){
        this.selectedIds = [];
        this.selectedRecords = [];
        for(let i=0; i<event.detail.rows.length;i++){
            for(let j=0; j<event.detail.rows[i].rows.length; j++){
                this.selectedIds.push(event.detail.rows[i].rows[j])
            }
            
        }
        for(let i=0; i<this.records.length; i++){
            if(this.selectedIds.includes(this.records[i].Id)){
                this.selectedRecords.push(this.records[i]);
            }
        }
        if(this.selectedRecords.length > 0){
            this.noSelectedRows = false;
        }else{
            this.noSelectedRows = true;
        }
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedIds', this.selectedIds));
    }

    onfinish(){
        window.location.reload();
        
    }

    onNext(){
        this.step = +this.step+1;

        if(this.step == 3){
            this.handleNext();
        }else{
            this.retrieveData();
        }
    }

    onPrevious(){
        this.step = +this.step-1;

        if(this.step == 1){
            let teSelectorId = "testExecutionSelectionTable";
            let element = this.template.querySelector('div[data-id="' + teSelectorId + '"]'); 
            element.style.display = "block";
        }
    }

    
    handleNext() {
        if (this.availableActions.find((action) => action === "NEXT")) {
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
        }
  }
}