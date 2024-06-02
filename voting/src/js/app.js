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
      App.displayVotes();
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
    App.contracts.Voting.deployed().then(function (instance) {
      return instance.getVotes.call();
    }).then(function (votes) {
      var votesTable = $("#votesTable");
      var historyTable = $("#historyTable");
      votesTable.empty();
      for (var i = 0; i < votes.length; i++) {
        var vote = votes[i];
        var endTime = new Date(vote.endTime * 1000).toLocaleString();
        var row = $("<tr>");
        row.append("<td>" + vote.name + "</td>");
        row.append("<td>" + vote.creator + "</td>");
        row.append("<td>" + endTime + "</td>");

        var joinButton = $("<button id='join' class='btn btn-primary btn-join'>Join</button>");
        joinButton.data("voteIndex", i);
        row.append($("<td>").append(joinButton));

        var voteButton = $("<button id='vote' class='btn btn-success btn-vote'>Vote</button>");
        voteButton.data("voteIndex", i);
        row.append($("<td>").append(voteButton));

        if (vote.closed) {
          historyTable.append(row); // Move to history table if vote is closed
        } else {
          votesTable.append(row); // Otherwise, keep in the votes table
        }
      }
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
