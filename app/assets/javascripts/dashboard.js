$(document).ready(function () {

  function requestGraph(g){
    var self = g;
    var data = [{data:[]}];
    var graph = new Rickshaw.Graph( {
      element: g,
      width: 380,
      height: 250,
      series: data,
      min: 'auto',
      interpolation: 'linear',
      renderer: 'line',
      padding: { top: 0.08, right: 0, bottom: 0.06, left: 0 },
    });

    var params = {};
    params = jQuery.parseJSON(self.dataset.options);

    var jqxhr = $.get( "remote_graph.json",params, function(response) {
      if(response){
        data[0].name = response['name'];
        data[0].data = response['data'];
        data[0].color = 'steelblue';
        graph.update();

        var hoverDetail = new Rickshaw.Graph.HoverDetail( {
          graph: graph,
          orientation: 'left',
        });

        var legend = new Rickshaw.Graph.Legend( {
          graph: graph,
          element: $(self).parent().find("#legend")[0]
        });

        var xAxis = new Rickshaw.Graph.Axis.Time({
          graph: graph,
          orientation: 'bottom',
        });

        var yAxis = new Rickshaw.Graph.Axis.Y({
          graph: graph,
          element: $(self).parent().find("#yaxis")[0]
        });
        yAxis.render();
        xAxis.render();
      }
    })
    .fail(function() {})
    .always(function() {});
  }

  $(".graph").each(function(g){
    requestGraph(this);
  });

  $(".refresh").click(function(g){
    //this should be redone at some point to refresh the already existing graph
    $(this).parent().find("#legend").html("");
    $(this).parent().find("#yaxis").html("");
    $(this).parent().find(".graph").html("");
    requestGraph($(this).parent().find(".graph")[0]);
  });

  var temp = "<ul>{{maketree}}</ul>";
  ich.addTemplate("keys", temp);

  function FormatKeys(keys){
    //Recursive Magic
    function NestKeys(obj,items){
      var item = items[0];
      if(items.length ==1){
        if(obj[item] == undefined) obj[item] = null;
        return true;
      }else{
        if(obj[item] == undefined) obj[item] = {};
        items.shift();
        NestKeys(obj[item],items);
      }
    }

    //Split each key on . to expand the key into nested keys
    var result = {};
    for(var key in keys){
      if(keys[key] != null){
        var nested = keys[key].split('.');
        NestKeys(result,nested);
      }
    }

    return result;
  }

  $.get( "keys.json", function(response) {
    var keys = FormatKeys(response);

    keys.maketree = function(self){
      if(self == undefined) self=this;
      var output = "";
      for(var key in self){
        if(typeof self[key] != 'function' && key != "_id" && key !="tojson"){
          if(self[key] != null){
            output +=  "<ul><label>" + key +"</label>" + this.maketree(self[key]) + "</ul>";
          }else{
            output += "<ul><label>" + key +"</label>" + "</ul>";
          }
        }
      }
      return output;
    };

    var html = ich.keys(keys);
    $("#metrics").html(html.text());

   // $("#metrics ul").hide();
    $("#metrics>ul:not(ul ul)").show();
    $("#metrics label").click(function(){
      $(this).parent().children("ul").toggle();
    });
  });

});