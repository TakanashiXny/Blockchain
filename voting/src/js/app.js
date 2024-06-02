App = {
  web3Provider: null,
  contracts: {},

  init: async function () {
    return await App.initWeb3();
  },

  initWeb3: async function () {
    // Initialize web3 and set the provider to the appropriate network
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        // Request account access
        await window.ethereum.enable();
      } catch (error) {
        console.error("User denied account access");
      }
    } else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
    } else {
      App.web3Provider = new Web3.providers.HttpProvider("http://localhost:7545");
    }
    web3 = new Web3(App.web3Provider);

    return App.initContract();
  },

  initContract: function () {
    // Load VotingContract.json and initiate the contract
    $.getJSON("Voting.json", function (data) {
      var VotingContractArtifact = data;
      App.contracts.Voting = TruffleContract(VotingContractArtifact);
      App.contracts.Voting.setProvider(App.web3Provider);
    });

    return App.bindEvents();
  },

  bindEvents: function () {
    // Bind click event for creating vote button
    $(document).on("click", "#createVoteBtn", App.handleCreateVote);
    // Bind click event for join vote button
    $(document).on("click", "#join", function () {
      var voteIndex = $(this).data("voteIndex");
      App.joinVote(voteIndex);
    });
    // Bind click event for vote button
    $(document).on("click", "#vote", function () {
      var voteIndex = $(this).data("voteIndex");
      App.showCandidatesModal(voteIndex);
    });
    $(document).on("click", "#showVotesLink", App.displayVotes);
  },

  handleCreateVote: function (event) {
    event.preventDefault();
    var voteName = $("#voteName").val();
    var maxVoters = $("#maxVoters").val();
    var endTime = new Date($("#endTime").val()).getTime() / 1000;

    App.contracts.Voting.deployed().then(function (instance) {
      return instance.createVote(voteName, maxVoters, endTime, { from: web3.eth.accounts[0] });
    }).then(function (result) {
      console.log(`The index of the vote: ${result}`);
      $("#createVoteModal").modal("hide");
      // Refresh votes display after creating a vote
      // App.displayVotes();
    }).catch(function (err) {
      console.error(err);
    });
  },

  joinVote: function (voteIndex) {
    console.log("Joining vote at index", voteIndex);
    $(".btn-join").eq(voteIndex).prop("disabled", true);
    // Implement logic for joining vote in the contract
  },

  showCandidatesModal: function (voteIndex) {
    console.log("Showing candidates for vote at index", voteIndex);
    $(".btn-vote").eq(voteIndex).prop("disabled", true);
    // Implement logic for showing candidates modal in the contract
  },

  displayVotes: function () {
    var votesTable = $("#votesTable");
    var historyTable = $("#historyTable");
    votesTable.empty();
    historyTable.empty();

    App.contracts.Voting.deployed().then(function (instance) {
      instance.NewVote({}, { fromBlock: 0, toBlock: 'latest' }).get(function (error, events) {
        if (!error) {
          events.forEach(function (event) {
            var { voteIndex, creator, name, maxVoters, endTime } = event.args;
            endTime = new Date(endTime.toNumber() * 1000).toLocaleString();

            var row = $("<tr>");
            row.append("<td>" + name + "</td>");
            row.append("<td>" + creator + "</td>");
            row.append("<td>" + endTime + "</td>");

            var joinButton = $("<button class='btn btn-primary btn-join'>Join</button>");
            joinButton.data("voteIndex", voteIndex.toNumber());
            row.append($("<td>").append(joinButton));

            var voteButton = $("<button class='btn btn-success btn-vote'>Vote</button>");
            voteButton.data("voteIndex", voteIndex.toNumber());
            row.append($("<td>").append(voteButton));

            votesTable.append(row);
          });
        }
      });

      // instance.VoteClosed({}, { fromBlock: 0, toBlock: 'latest' }).get(function (error, events) {
      //   if (!error) {
      //     events.forEach(function (event) {
      //       var { voteIndex, winner } = event.args;

      //       $("#votesTable tr").each(function () {
      //         var row = $(this);
      //         var idx = row.find(".btn-join").data("voteIndex");

      //         if (idx === voteIndex.toNumber()) {
      //           var closedRow = row.clone();
      //           closedRow.find("td:last").remove(); // Remove join button cell
      //           closedRow.find("td:last").remove(); // Remove vote button cell
      //           closedRow.append("<td>" + winner + "</td>");
      //           closedRow.appendTo(historyTable);
      //           row.remove();
      //         }
      //       });
      //     });
      //   }
      //});
    }).catch(function (err) {
      console.error(err);
    });
  }
};

$(function () {
  $(window).load(function () {
    App.init();
  });
});
