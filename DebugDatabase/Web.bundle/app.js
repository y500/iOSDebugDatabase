$( document ).ready(function() {
    $("#query").keypress(function(e){
        if(e.which == 13) {
            queryFunction();
        }
    });
    //update currently selected database
    $( document ).on( "click", "#db-list .list-group-item", function() {
        $("#db-list .list-group-item").each(function() {
            $(this).removeClass('selected');
        });
        $(this).addClass('selected');
    });

    //update currently table database
    $( document ).on( "click", "#table-list .list-group-item", function() {
        $("#table-list .list-group-item").each(function() {
            $(this).removeClass('selected');
        });
        $(this).addClass('selected');
    });


});



var currentDatabaseName;

function getData(tableName) {

   $.ajax({url: "allTableRecords?tableName="+tableName+"&database="+currentDatabaseName, success: function(result){

//           result = JSON.parse(result);
           inflateData(result);

   }});

}

function queryFunction() {

   var query = $('#query').val();

   $.ajax({url: "query?query="+escape(query)+"&database="+currentDatabaseName, success: function(result){

//           result = JSON.parse(result);
           inflateData(result);

   }});

}

function downloadDb() {
    if (currentDatabaseName) {
        $.ajax({url:  "downloadDb?database="  + currentDatabaseName, success: function(){
             window.location = "downloadDb?database="  + currentDatabaseName;
        }});
    }
}


function getDBList() {

   $.ajax({url: "databaseList", success: function(result){

           var dbList = result.rows;
           $('#db-list').empty();
           var isSelectionDone = false;
           for(var count = 0; count < dbList.length; count++){
             if(dbList[count].indexOf("journal") == -1){
                $("#db-list").append("<a href='#' id=" +dbList[count] + " class='list-group-item' onClick='openDatabaseAndGetTableList(\""+ dbList[count] + "\");'>" +dbList[count] + "</a>");
                if(!isSelectionDone){
                    isSelectionDone = true;
                      $('#db-list').find('a').trigger('click');
                }
             }
           }

   }});

}

function openDatabaseAndGetTableList(db) {
    
    if("NSUserDefault" == db) {
        $('#run-query').removeClass('active');
        $('#run-query').addClass('disabled');
//        $('#selected-db-info').removeClass('active');
//        $('#selected-db-info').addClass('disabled');
        $('#selected-db-info').removeClass('disabled');
        $('#selected-db-info').addClass('active');
        currentDatabaseName = "NSUserDefault";
        $("#selected-db-info").text("Export NSUserDefault");
    } else {
        $('#run-query').removeClass('disabled');
        $('#run-query').addClass('active');
        $('#selected-db-info').removeClass('disabled');
        $('#selected-db-info').addClass('active');
        currentDatabaseName = db;
        $("#selected-db-info").text("Export Selected Database : "+db);
    }


   $.ajax({url: "tableList?database="+db, success: function(result){

//           result = JSON.parse(result);
           var tableList = result.rows;
           var dbVersion = result.dbVersion;
           if("NSUserDefault" != db) {
              $("#selected-db-info").text("Export Selected Database : "+db +" Version : "+dbVersion);
           }
           $('#table-list').empty()
           for(var count = 0; count < tableList.length; count++){
             var tableName = tableList[count];
             $("#table-list").append("<a href='#' data-db-name='"+db+"' data-table-name='"+tableName+"' class='list-group-item' onClick='getData(\""+ tableName + "\");'>" +tableName + "</a>");
           }

   }});

}

function inflateData(result){

   if(result.isSuccessful){

      if(!result.isSelectQuery){
         showSuccessInfo("Query Executed Successfully");
         return;
      }

      var columnHeader = result.tableInfos;

      // set function to return cell data for different usages like set, display, filter, search etc..
      for(var i = 0; i < columnHeader.length; i++) {
        columnHeader[i]['targets'] = i;
        columnHeader[i]['data'] = function(row, type, val, meta) {
            var dataType = row[meta.col].dataType;
            if (type == "sort" && dataType == "boolean") {
                return row[meta.col].value ? 1 : 0;
            }
            return row[meta.col].value;
        }
      }
      var columnData = result.rows;
       var tableId = "#db-data";
        if ($.fn.DataTable.isDataTable(tableId) ) {
          $(tableId).DataTable().destroy();
        }

       $("#db-data-div").remove();
       $("#parent-data-div").append('<div id="db-data-div"><table class="display nowrap" cellpadding="0" border="0" cellspacing="0" width="100%" class="table table-striped table-bordered display" id="db-data"></table></div>');

       if (result.userDefault) {
           $(tableId).dataTable({
                                "data": columnData,
                                "columnDefs": columnHeader,
                                'bPaginate': true,
                                'searching': true,
                                'bFilter': true,
                                'bInfo': true,
                                "bSort" : true,
                                "scrollX": true,
                                "iDisplayLength": 10
                                })
       }else {
           $(tableId).dataTable({
                                "data": columnData,
                                "columnDefs": columnHeader,
                                'bPaginate': true,
                                'searching': true,
                                'bFilter': true,
                                'bInfo': true,
                                "bSort" : true,
                                "scrollX": true,
                                "iDisplayLength": 10,
                                "dom": "Bfrtip",
                                select: 'single',
                                altEditor: true,     // Enable altEditor
                                buttons: [
                                          {
                                          extend: 'selected', // Bind to Selected row
                                          text: 'Edit',
                                          name: 'edit'        // do not change name
                                          },
                                          {
                                          extend: 'selected',
                                          text: 'Delete',
                                          name: 'delete'
                                          }
                                          ]
                                })
       }

       //attach row-updated listener
       $(tableId).on('update-row.dt', function (e, updatedRowData, callback) {
            var updatedRowDataArray = JSON.parse(updatedRowData);
            //add value for each column
            var data = columnHeader;
            for(var i = 0; i < data.length; i++) {
                data[i].value = updatedRowDataArray[i].value;
                data[i].dataType = updatedRowDataArray[i].dataType;
            }
            //send update table data request to server
            updateTableData(data, callback);
       });


       //attach delete-updated listener
       $(tableId).on('delete-row.dt', function (e, updatedRowData, callback) {
            var deleteRowDataArray = JSON.parse(updatedRowData);

            console.log(deleteRowDataArray);

            //add value for each column
            var data = columnHeader;
            for(var i = 0; i < data.length; i++) {
                data[i].value = deleteRowDataArray[i].value;
                data[i].dataType = deleteRowDataArray[i].dataType;

            }

            //send delete table data request to server
            deleteTableData(data, callback);
       });

       // hack to fix alignment issue when scrollX is enabled
       $(".dataTables_scrollHeadInner").css({"width":"100%"});
       $(".table ").css({"width":"100%"});
   }else{
      if(!result.isSelectQuery){
         showErrorInfo("Query Execution Failed");
      }else {
          if(result.errorMessage){
              showErrorInfo(result.errorMessage);
          }else{
              showErrorInfo("Some Error Occurred");
          }
      }
   }

}

function inflateAppInfoData(result){

    if(result.isSuccessful){

        if(!result.isSelectQuery){
            showSuccessInfo("Query Executed Successfully");
            return;
        }

        var columnHeader = result.tableInfos;

        // set function to return cell data for different usages like set, display, filter, search etc..
        for(var i = 0; i < columnHeader.length; i++) {
            columnHeader[i]['targets'] = i;
            columnHeader[i]['data'] = function(row, type, val, meta) {
                var dataType = row[meta.col].dataType;
                if (type == "sort" && dataType == "boolean") {
                    return row[meta.col].value ? 1 : 0;
                }
                return row[meta.col].value;
            }
        }
        var columnData = result.rows;
        var tableId = "#db-appinfo";
        if ($.fn.DataTable.isDataTable(tableId) ) {
            $(tableId).DataTable().destroy();
        }

        $("#db-appinfo-div").remove();
        $("#parent-appinfo-div").append('<div id="db-appinfo-div"><table class="display nowrap" cellpadding="0" border="0" cellspacing="0" width="100%" class="table table-striped table-bordered display hide-column-names" id="db-appinfo"></table></div>');

        $(tableId).dataTable({
            "data": columnData,
            "columnDefs": columnHeader,
            'bPaginate': false,
            'searching': false,
            'bFilter': false,
            'bInfo': false,
            "bSort" : false,
            "scrollX": true,
            "iDisplayLength": 99,
            "fnDrawCallback": function (oSettings) {
                $(oSettings.nTHead).hide();
            }
        })

        // hack to fix alignment issue when scrollX is enabled
        $(".dataTables_scrollHeadInner").css({"width":"100%"});
        $(".table ").css({"width":"100%"});
    }else{
        if(!result.isSelectQuery){
            showErrorInfo("Query Execution Failed");
        }else {
            if(result.errorMessage){
                showErrorInfo(result.errorMessage);
            }else{
                showErrorInfo("Some Error Occurred");
            }
        }
    }

}

//send update database request to server
function updateTableData(updatedData, callback) {
    //get currently selected element
    var selectedTableElement = $("#table-list .list-group-item.selected");

    var filteredUpdatedData = updatedData.map(function(columnData){
        return {
            title: columnData.title,
            isPrimary: columnData.isPrimary,
            value: columnData.value,
            dataType: columnData.dataType
        }
    });
    //build request parameters
    var requestParameters = {};
    requestParameters.database = selectedTableElement.attr('data-db-name');
    requestParameters.tableName = selectedTableElement.attr('data-table-name');;
    requestParameters.updatedData = encodeURIComponent(JSON.stringify(filteredUpdatedData));

    //execute request
    $.ajax({
        url: "updateRecord",
        type: 'GET',
        data: requestParameters,
        success: function(response) {
           console.log(response);
           console.log(response.isSuccessful);
//            response = JSON.parse(response);
            if(response.isSuccessful){
               console.log("Data updated successfully");
               callback(true);
               showSuccessInfo("Data Updated Successfully");
            } else {
               console.log("Data updated failed");
               callback(false);
            }
        }
    })
}


function deleteTableData(deleteData, callback) {

    var selectedTableElement = $("#table-list .list-group-item.selected");
        var filteredUpdatedData = deleteData.map(function(columnData){
            return {
                title: columnData.title,
                isPrimary: columnData.isPrimary,
                value: columnData.value,
                dataType: columnData.dataType
            }
        });

        console.log(filteredUpdatedData);

        //build request parameters
        var requestParameters = {};
        requestParameters.database = selectedTableElement.attr('data-db-name');
        requestParameters.tableName = selectedTableElement.attr('data-table-name');;
        requestParameters.deleteData = encodeURIComponent(JSON.stringify(filteredUpdatedData));

        //execute request
        $.ajax({
            url: "deleteRecord",
            type: 'GET',
            data: requestParameters,
            success: function(response) {
//                response = JSON.parse(response);
                if(response.isSuccessful){
                   console.log("Data deleted successfully");
                   callback(true);
                   showSuccessInfo("Data Deleted Successfully");
                } else {
                   console.log("Data delete failed");
                   callback(false);
                }
            }
    })
}

function showSuccessInfo(message){
    var snackbarId = "snackbar";
    var snackbarElement = $("#"+snackbarId);
    snackbarElement.addClass("show");
    snackbarElement.css({"backgroundColor": "#5cb85c"});
    snackbarElement.html(message)
    setTimeout(function(){
        snackbarElement.removeClass("show");
    }, 3000);
}

function showErrorInfo(message){
    var snackbarId = "snackbar";
    var snackbarElement = $("#"+snackbarId);
    snackbarElement.addClass("show");
    snackbarElement.css({"backgroundColor": "#d9534f"});
    snackbarElement.html(message)
    setTimeout(function(){
        snackbarElement.removeClass("show");
    }, 3000);
}

function getUserDefault() {
    $.ajax({url: "getUserDefault", success: function(result){
           inflateData(result);
    }});
}

function getAppInfo() {
    $.ajax({url: "getAppInfo", success: function(result){
           inflateAppInfoData(result);
           getUserDefault();
    }});
}
