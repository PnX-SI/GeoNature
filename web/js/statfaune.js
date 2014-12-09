var d0,d1,d2,d3,d4,d5;
	$(function() {
         //---------------graf 1-----------------------------
        var dataUrlNbObs = 'datasnbobscf';
        var dataUrlColors = 'datascolorscf';
        var dataUrlNbObsInv = 'datasnbobsinv';
        var dataUrlColorsInv = 'datascolorsinv';
        function onDataReceived1(series) {
            var d0 = series[0];
            var d1 = series[1];
            var d2 = series[2];
            var data = 
            [ 
                {
                    color: 'black'
                    ,data: d0
                    ,label: 'nombre total de saisies'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                },{
                    color: 'blue'
                    ,data: d1
                    ,label: 'nombre de saisies "web"'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                },{
                    color: 'green'
                    ,data: d2
                    ,label: 'nombre de saisies "nomade"'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                }
            ];
            var options = 
            {
                series: {
                    lines: { show: true },
                    points: { show: true }
                }
                ,grid: {
                    hoverable: true,
                    clickable: true
                }
                ,xaxis: {
                    mode: "time"
                    ,timeformat: "%d/%m/%y"
                    ,minTickSize: [1, "day"]
                }
            };
            $.plot("#placeholder1", data, options);
        };
        $.ajax({
            url: dataUrlNbObs,
            type: "GET",
            dataType: "json",
            success: onDataReceived1
        });
         
        //---------------graf 2-----------------------------
         //on construit les variables du graphique
        function onDataReceived2(series) {
            d3 = series[0];
            d4 = series[1];
            d5 = series[2];
            var data = 
            [ 
                {
                    color: 'yellow'
                    ,data: d3
                    ,label: 'jamais vue'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                }
                ,{
                    color: 'red'
                    ,data: d4
                    ,label: 'A rechercher'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                },{
                    color: 'gray'
                    ,data: d5
                    ,label: 'vue'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                }
            ];
            var options = 
            { 
                series: {
                    lines: { show: true },
                    points: { show: true }
                }
                ,grid: {
                    hoverable: true,
                    clickable: true
                }
                ,xaxis: {
                    mode: "time"
                    ,timeformat: "%d/%m/%y"
                    ,minTickSize: [1, "day"]
                }
            };
            //on construit le graphique
            $.plot("#placeholder2", data, options);   
        };
         //on lance les requêtes ajax
        $.ajax({
            url: dataUrlColors,
            type: "GET",
            dataType: "json",
            success: onDataReceived2
        });
        
        function onDataReceived3(series) {
            var d6 = series[0];
            var d7 = series[1];
            var d8 = series[2];
            var data = 
            [ 
                {
                    color: 'black'
                    ,data: d6
                    ,label: 'nombre total de saisies'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                },{
                    color: 'blue'
                    ,data: d7
                    ,label: 'nombre de saisies "web"'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                },{
                    color: 'green'
                    ,data: d8
                    ,label: 'nombre de saisies "nomade"'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                }
            ];
            var options = 
            {
                series: {
                    lines: { show: true },
                    points: { show: true }
                }
                ,grid: {
                    hoverable: true,
                    clickable: true
                }
                ,xaxis: {
                    mode: "time"
                    ,timeformat: "%d/%m/%y"
                    ,minTickSize: [1, "day"]
                }
            };
            $.plot("#placeholder3", data, options);
        };
        $.ajax({
            url: dataUrlNbObsInv,
            type: "GET",
            dataType: "json",
            success: onDataReceived3
        });
        
        //---------------graf 2-----------------------------
         //on construit les variables du graphique
        function onDataReceived4(series) {
            d9 = series[0];
            d10 = series[1];
            d11 = series[2];
            var data = 
            [ 
                {
                    color: 'yellow'
                    ,data: d9
                    ,label: 'jamais vue'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                }
                ,{
                    color: 'red'
                    ,data: d10
                    ,label: 'A rechercher'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                },{
                    color: 'gray'
                    ,data: d11
                    ,label: 'vue'
                    ,clickable: true
                    ,hoverable: true
                    ,shadowSize: 5
                    ,highlightColor: 'yellow'
                }
            ];
            var options = 
            { 
                series: {
                    lines: { show: true },
                    points: { show: true }
                }
                ,grid: {
                    hoverable: true,
                    clickable: true
                }
                ,xaxis: {
                    mode: "time"
                    ,timeformat: "%d/%m/%y"
                    ,minTickSize: [1, "day"]
                }
            };
            //on construit le graphique
            $.plot("#placeholder4", data, options);   
        };
         //on lance les requêtes ajax
        $.ajax({
            url: dataUrlColorsInv,
            type: "GET",
            dataType: "json",
            success: onDataReceived4
        });
        
        function showTooltip(x, y, contents) {
			$("<div id='tooltip'>" + contents + "</div>").css({
				position: "absolute",
				display: "none",
				top: y + 5,
				left: x + 5,
				border: "1px solid #fdd",
				padding: "2px",
				"background-color": "#fee",
				opacity: 0.80
			}).appendTo("body").fadeIn(200);
		}

		var previousPoint = null;
		 $("#placeholder1").bind("plothover", function (event, pos, item) {
            if (item) {
                if (previousPoint != item.dataIndex) {
                    previousPoint = item.dataIndex;
                    $("#tooltip").remove();
                    var x = item.datapoint[0],
                    y = item.datapoint[1];
                    var d = new Date(x);
                    showTooltip(item.pageX, item.pageY, y + ' données au ' + d.getUTCDate()+'/'+(d.getUTCMonth()+1)+'/'+d.getUTCFullYear());
                }
            } else {
                $("#tooltip").remove();
                previousPoint = null;            
            }
		});
        $("#placeholder2").bind("plothover", function (event, pos, item) {
            if (item) {
                if (previousPoint != item.dataIndex) {
                    previousPoint = item.dataIndex;
                    $("#tooltip").remove();
                    var x = item.datapoint[0],
                    y = item.datapoint[1];
                    showTooltip(item.pageX, item.pageY,item.series.label + " : " + y);
                }
            } else {
                $("#tooltip").remove();
                previousPoint = null;            
            }
		});
        $("#placeholder3").bind("plothover", function (event, pos, item) {
            if (item) {
                if (previousPoint != item.dataIndex) {
                    previousPoint = item.dataIndex;
                    $("#tooltip").remove();
                    var x = item.datapoint[0],
                    y = item.datapoint[1];
                    var d = new Date(x);
                    showTooltip(item.pageX, item.pageY, y + ' données au ' + d.getUTCDate()+'/'+(d.getUTCMonth()+1)+'/'+d.getUTCFullYear());
                }
            } else {
                $("#tooltip").remove();
                previousPoint = null;            
            }
		});
        $("#placeholder4").bind("plothover", function (event, pos, item) {
            if (item) {
                if (previousPoint != item.dataIndex) {
                    previousPoint = item.dataIndex;
                    $("#tooltip").remove();
                    var x = item.datapoint[0],
                    y = item.datapoint[1];
                    showTooltip(item.pageX, item.pageY,item.series.label + " : " + y);
                }
            } else {
                $("#tooltip").remove();
                previousPoint = null;            
            }
		});

        // Add the Flot version string to the footer
        $("#footer").prepend("Flot " + $.plot.version + " &ndash; ");
	});