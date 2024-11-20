import { LightningElement } from 'lwc';
import saveFile from '@salesforce/apex/importSurveyDataController.saveFile';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class ImportSurveys extends LightningElement 
{

    importData = false;
    data;

    errMessage;
    
    fileDataQ;
    fileDataA;
    fileNameQ;
    fileNameA;

    UploadFile = 'Upload CSV File';
    showLoadingSpinner = false;
    isTrue = false;

    MAX_FILE_SIZE = 1500000;

    handleImportButton()
    {
        this.importData = true;
    }

    handleFilesChangeQ(event) 
    {
        const file = event.target.files[0];
        this.fileNameQ = file.name;
        console.log('fileNameQ: ' + this.fileNameQ);
        var reader = new FileReader();
        reader.onloadend  = () => {
            var base64 = reader.result;
            this.fileDataQ = base64;
        }
        reader.readAsText(file);
    }

    handleFilesChangeA(event) 
    {
        const file = event.target.files[0];
        this.fileNameA = file.name;
        console.log('fileNameA: ' + this.fileNameA);
        var reader = new FileReader()
        reader.onloadend = () => {
            var base64 = reader.result;
            this.fileDataA = base64;
        }
        reader.readAsText(file); 
    }

    handleSave()
    {   
        if (!this.fileNameQ || !this.fileNameA)
            this.displayMessage('Error', 
            'Must enter both Questions and Answer files...', 
            'error');
        else if ( (this.fileNameQ && this.fileNameQ.indexOf('.csv') == -1 ) ||
                  (this.fileNameA && this.fileNameA.indexOf('.csv') == -1 ) )
            this.displayMessage('Error', 
                'Can ONLY upload files with extention of csv...', 
                'error');
        else
            this.saveTheFiles();
    }

    saveTheFiles()
    {
        this.showLoadingSpinner = true;

        console.log('fileDataQ: ' + JSON.stringify(this.fileDataQ));
        console.log('fileDataA: ' + JSON.stringify(this.fileDataA));
        saveFile({ fileDataQ : JSON.stringify(this.fileDataQ), 
            fileDataA : JSON.stringify(this.fileDataA) })
        .then(result=>
            {
                console.log('result ====> ' + result);
                if (result) 
                {
                    this.errMessage = (result + ' ').split(',');
                    if (result.indexOf('Error:') >= 0)
                        this.displayMessage('Error while uploading Files', result, 'error');
                    else
                        this.displayMessage('Success', 'Files Uploaded Successfully...', 'success');
                }
                else
                {
                    this.isTrue = false;
                    this.showLoadingSpinner = false;
                    this.displayMessage('Success', 'Files Uploaded Successfully...', 'success');
                    this.importData = false;
                }
            })
        .catch(error => 
            {
                console.log(error);
                this.displayMessage('Error while uploading Files...', error.message, 'error');
            });
    }

    displayMessage (tit, msg, vari)
    {
        this.showLoadingSpinner = false;
        console.log('Error event: ' + msg);
        this.dispatchEvent(
            new ShowToastEvent({
                title: tit,
                message: msg,
                variant: vari,
            }),
        );
    }
}