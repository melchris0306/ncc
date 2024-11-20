import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ACCORDION_STYLE from '@salesforce/resourceUrl/customIndependentSurvey';
import { refreshApex } from '@salesforce/apex';
import getSurveyFieldsFromMetadata from '@salesforce/apex/SurveyFieldPickerController.getSurveyFieldsFromMetadata';
import saveSelectedFields from '@salesforce/apex/SurveyFieldPickerController.saveSelectedFields';

export default class SurveyFieldPicker extends LightningElement {
    
    @track fieldList = [];
    isReadOnly = true;
    showSpinner = true;
    isRendered = false;
    accordionSection = 'SurveyFields';
    @api recordId;

    connectedCallback(){
       getSurveyFieldsFromMetadata({surveyId : this.recordId})
        .then((result) => {
            if (result != null && result.length > 0) {
                this.fieldList = result;
            }

            this.showSpinner = false;
        })
        .catch((error) => {
            this.showNotification('Error', 'Encountered an error while fetching survey record. Error: ' + error.message, 'error');
            this.showSpinner = false;
        });
    }

    renderedCallback(){
        if (!this.isRendered){
            loadStyle(this, ACCORDION_STYLE),
            this.isRendered = true;
        } else {
            this.tickSelectAll('fieldCheckbox', 'selectAllFieldCheckbox');
            this.tickSelectAll('requiredCheckbox', 'selectAllRequiredCheckbox');
        }
    }

    handleToggleSection(event) {
        if(this.accordionSection.length === 0){
            this.accordionSection = '';
        } else{
            this.accordionSection = 'SurveyFields';
        }
    }

    enableEdit(){
        this.isReadOnly = false;
    }

    handleCancel(){
        //revert values in UI
        let selectedFieldList = this.template.querySelectorAll('[data-id="fieldCheckbox"]');
        let requiredList = this.template.querySelectorAll('[data-id="requiredCheckbox"]');
        
        for(let i = 0; i < this.fieldList.length; i++) {
            selectedFieldList[i].checked = this.fieldList[i].isSelected;
            requiredList[i].checked = this.fieldList[i].isRequired;
        }

        this.tickSelectAll('fieldCheckbox', 'selectAllFieldCheckbox');
        this.tickSelectAll('requiredCheckbox', 'selectAllRequiredCheckbox');
        this.isReadOnly = true;
    }

    handleSaveSelectedFields(){
        this.isReadOnly = true;
        this.showSpinner = true;

        let selectionList = {};
        let currentFieldList = this.template.querySelectorAll('[data-id="fieldCheckbox"]');

        //run through currently selected fields
        for(let i = 0; i < currentFieldList.length; i++) {
            let apiName = currentFieldList[i].getAttribute("data-api-name");
            let objectName = currentFieldList[i].getAttribute("data-object-name");
            let required = this.template.querySelector('[data-related="'+ apiName +'"]').checked;

            if (currentFieldList[i].checked){
                selectionList[objectName + "|" + apiName] = required;
            } else {
                this.template.querySelector('[data-related="'+ apiName +'"]').checked = false;
            }
        }

        saveSelectedFields({selectedFields : JSON.stringify(selectionList), surveyId : this.recordId})
        .then((result) => {
            this.saveSelectionIntoObject();
            this.showNotification('Success', 'Survey Fields update successful', 'success');

            //reset select all
            this.tickSelectAll('fieldCheckbox', 'selectAllFieldCheckbox');
            this.tickSelectAll('requiredCheckbox', 'selectAllRequiredCheckbox');
            this.showSpinner = false;
        })
        .catch((error) => {
            this.showNotification('Error', 'Encountered an error while updating Survey Fields. Error: ' + error.message, 'error');
            this.showSpinner = false;
        });
    }

    saveSelectionIntoObject(){
        //persists the selections into the js object for correct behavior on cancel etc
        let tempRecordList = Object.assign([], this.fieldList);
        let selectedFieldList = this.template.querySelectorAll('[data-id="fieldCheckbox"]');
        let requiredList = this.template.querySelectorAll('[data-id="requiredCheckbox"]');

        for (let i = 0; i < this.fieldList.length; i++) {
            let tempRec = Object.assign({}, tempRecordList[i]);
            tempRec.isSelected = selectedFieldList[i].checked;
            tempRec.isRequired = requiredList[i].checked;
            tempRecordList[i] = tempRec;
        }

        this.fieldList = tempRecordList;
    }

     // Toast message method
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    checkIfAllRequiredCheckboxSelected(event){
        let singleCheckBox = event.target.getAttribute("data-id");
        let selectAllBox = (singleCheckBox === "fieldCheckbox") ? "selectAllFieldCheckbox" : "selectAllRequiredCheckbox";

        this.tickSelectAll(singleCheckBox, selectAllBox);

        if (singleCheckBox === "fieldCheckbox"){
            this.untickRequired(event);
        } else {
            this.tickFieldCheckBox(event);
        }
    }

    //tick select all if all individual checkboxes are ticked
    tickSelectAll(checkboxGroupName, selectAllCheckBoxName){
        //check if all field checkboxes are selected, then also check the corresponding field select all checkbox
        let fieldCheckboxes = this.template.querySelectorAll('[data-id="'+ checkboxGroupName +'"]');
        let areAllSelected = true;

        for(let i = 0; i < fieldCheckboxes.length; i++) {
            
            if (!fieldCheckboxes[i].checked){
                areAllSelected = false;
            }
        }

        this.template.querySelector('[data-id="' + selectAllCheckBoxName + '"]').checked = areAllSelected;
    }

    //untick Required if field is unselected
    untickRequired(event){
        let target = event.target;

        if (!target.checked){
            this.template.querySelector('[data-related="' + target.getAttribute("data-api-name") + '"]').checked = false;
        }
    }

    tickFieldCheckBox(event){
        let target = event.target;

        if (target.checked){
            this.template.querySelector('[data-api-name="' + target.getAttribute("data-related") + '"]').checked = true;
            this.tickSelectAll('fieldCheckbox', 'selectAllFieldCheckbox');
        }
    }

    selectAllCheckBoxInSameColumn(event){
        let target = (event.target.getAttribute("data-id") === "selectAllFieldCheckbox") ? "fieldCheckbox" : "requiredCheckbox";
        let checkboxes = this.template.querySelectorAll('[data-id="'+ target +'"]');

        for(let i = 0; i < checkboxes.length; i++) {
            checkboxes[i].checked = event.target.checked;
        }

        if (target === "fieldCheckbox" && !event.target.checked){
            let checkboxes = this.template.querySelectorAll('[data-id="requiredCheckbox"]');

            for(let i = 0; i < checkboxes.length; i++) {
                checkboxes[i].checked = false;
            }

            this.template.querySelector('[data-id="selectAllRequiredCheckbox"]').checked = false;
        }
    }
}