import { LightningElement, api } from 'lwc';
import COMPASS_EVENT_PAGE_RESOURCE from '@salesforce/resourceUrl/CompassEventPage';

export default class CompassTable extends LightningElement {
    sortIcon = COMPASS_EVENT_PAGE_RESOURCE + '/Icons/SortIcon.svg';
    @api keyField = 'Id'; // default Id field.
    @api columns = []; 
    @api rows = []; 
    // sort properties
    @api sortOptions = [];
    initialRows = [];
    _hasSortbutton = false;
    selectedSortOption = '';
    isSortOpen = false;

    @api
    get hasSortbutton(){
        return this._hasSortbutton;
    }
    set hasSortbutton(hasSort){
        if(typeof hasSort === 'string'){
            this._hasSortbutton = hasSort.includes('true') ? true : false;
        }
        
        if(typeof hasSort !== 'boolean') return;

        this._hasSortbutton = hasSort;
    }

    connectedCallback(){
        this.initialRows = this.rows;
        this.setColumnWidth();
        this.initSortOptions();
        this.mapRowValues(this.rows);
    }

    handleSortButtonClick(){
        this.isSortOpen = !this.isSortOpen;
    }

    handleSortOptionChange(event){
        let selectedOption = event.target.value;
        this.rows = this.sortData(this.initialRows, selectedOption);
        this.mapRowValues(this.rows);
    }

    // hasArrayData(arrayData){
    //     return (Array.isArray(arrayData) && arrayData.length);
    // }

    setColumnWidth(){
        this.columns = this.columns.map(column => {
            let newColumn = {...column};
            if(newColumn.fixedWidth) newColumn.style = `width: ${column.fixedWidth};`;
            return newColumn;
        });

        console.log('this.columns ', JSON.stringify(this.columns));
    }

    initSortOptions(){
        if(this.sortOptions) return;

        let options = [];
        this.columns.forEach(column => {
            if(column.fieldName) options.push({ label: column.label, value: column.fieldName });
        });
        
        this.sortOptions = options;
    }

    mapRowValues(rows){
        this.rows = rows.map(row => {
            let newRow = {};
            newRow.keyField = row[this.keyField];
            newRow.cells = [];

            newRow.cells = this.columns.map(column => {
                let cell = {};
                cell.data = row[column.fieldName];
                cell.fieldName = column.fieldName;
                return cell;
            });

            return newRow;
        });
        console.log('_rows ', JSON.stringify(this.rows));
    }

    sortData(arr, columnToCompare){
        let sortedArr = [...arr];
        sortedArr.sort(function(a, b){
            if ( a[columnToCompare] < b[columnToCompare] ){
                return -1;
            }
            if ( a[columnToCompare] > b[columnToCompare] ){
                return 1;
            }
            return 0;
        });
        
        return sortedArr;
    }
}