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
    // Bind click event for vote button
    $(document).on("click", "#vote", function () {
      var voteIndex = $(this).data("voteIndex");
      App.showCandidatesModal(voteIndex);
    });
    $(document).on("click", "#showVotesLink", App.displayCurrentVotes);
    $(document).on("click", "#showHistoryLink", App.displayClosedVotes);
    $(document).on("click", "#candidateConfirm", App.joinVote);
    $(document).on("click", "#getHashesButton", App.displayTransactionHashes);
  },

  handleCreateVote: function (event) {
    event.preventDefault();
    var voteName = $("#voteName").val();
    var maxVoters = $("#maxVoters").val();
    var endTime = new Date($("#endTime").val()).getTime() / 1000;
    console.log(voteName);
    App.contracts.Voting.deployed().then(function (instance) {
      instance.createVote(voteName, maxVoters, endTime, { from: web3.eth.accounts[0], value: web3.toWei(10, "ether"), payable: true }).then(function (result) {
        console.log(`The index of the vote: ${result}`);
        $("#createVoteModal").modal("hide");
        // Refresh votes display after creating a vote
        // App.displayVotes();
        document.getElementById('showVotesPage').classList.remove('hide');
        document.getElementById('createVotePage').classList.add('hide');
        App.displayCurrentVotes();
      })
    }).catch(function (err) {
      console.error(err);
    });
  },

  joinVote: function (instance, voteIndex) {
    console.log("Joining vote at index", voteIndex);
    $(".btn-join").eq(voteIndex);
    // Implement logic for joining vote in the contract
    return instance.addCandidate(voteIndex, { from: web3.eth.accounts[0], value: web3.toWei(6, "ether"), payable: true });
  },

  getCandidates: function(instance, voteIndex) { 
    return new Promise((resolve, reject) => {
      var candidates = instance.getCandidates.call(voteIndex);
      resolve(candidates);
    });
  },

  getVotes: function () {
    // return new Promise((resolve, reject) => {
    //   App.contracts.Voting.deployed().then(function(instance) {
    //       return instance.getOpenVotes.call();
    //   }).then(function(votes) {
    //       resolve(votes);
    //       console.log("votes:");
    //       console.log(votes);
    //   }).catch(function(err) {
    //       console.error(err);
    //       reject(err);
    //   });
    // });
    return App.contracts.Voting.deployed().then(function(instance) {
      console.log(instance.getVotes.call());
      console.log(instance.getOpenVotes.call());
        return instance.getOpenVotes.call();
    });
  },

  getClosedVotes: function () {
    return new Promise((resolve, reject) => {
      App.contracts.Voting.deployed().then(function(instance) {
          return instance.getClosedVotes.call();
      }).then(function(votes) {
          resolve(votes);
      }).catch(function(err) {
          console.error(err);
          reject(err);
      });
    });
  },

  handleVoteClosed: function(voteIndex) {
    // Remove the vote row from active votes table
    App.contracts.Voting.deployed().then(function (instance) {
      return instance.getWinner(voteIndex, { from: web3.eth.accounts[0] });
    }).then (function (result) {
      console.log(result);
      $('#votesTable tr').each(function() {
        var row = $(this);
        var cell = row.find("td:eq(3) button");
        if (cell.data("voteIndex") == voteIndex.toNumber()) {
          var voteName = row.find("td:eq(0)").text();
          var creatorAddress = row.find("td:eq(1)").text();
          row.remove();
          
          // Add to history table
          var historyRow = $("<tr>");
          historyRow.append("<td>" + voteName + "</td>");
          historyRow.append("<td>" + creatorAddress + "</td>");
          historyRow.append("<td>" + result + "</td>");
          $('#historyTable').append(historyRow);
        }
      });
    }) 
  },

  showCandidatesModal: function (voteIndex) {
    console.log("Showing candidates for vote at index", voteIndex);
    $(".btn-vote").eq(voteIndex).prop("disabled", true);
    // Implement logic for showing candidates modal in the contract
  },

  displayCurrentVotes: function () {
    var votesTable = $("#votesTable");
    votesTable.empty();

    App.contracts.Voting.deployed().then(function (instance) {
        instance.getVoteNum.call().then(function (total_) {
            var total = total_.toNumber(); // Assuming total_ is a BigNumber object
            console.log("total");
            console.log(total);

            var votePromises = [];
            for (var i = 0; i < total; i++) {
                votePromises.push(instance.getVote.call(i));
            }

            Promise.all(votePromises).then(function (votes) {
                votes.forEach(function (t, i) {
                    console.log(t);

                    var closed = t[0];
                    var creator = t[1];
                    var name = t[2];
                    var endTime = new Date(t[3].toNumber() * 1000).toLocaleString();;
                    var winner = t[4];

                    if (!closed) {
                        var row = $("<tr>");
                        row.append("<td>" + name + "</td>");
                        row.append("<td>" + creator + "</td>");
                        row.append("<td>" + endTime + "</td>");

                        let joinButton = $("<button id='join' class='btn btn-primary btn-join'>Join</button>");
                        joinButton.data("voteIndex", i);
                        row.append($("<td>").append(joinButton));

                        joinButton.click(function() {
                            var voteIndex = $(this).data("voteIndex");
                            $('#joinModal').modal('show'); // 显示模态框
                            $('#candidateConfirm').off().on('click', function() {
                                $('#joinModal').modal('hide');
                                App.joinVote(instance, voteIndex);
                            });

                            $('#candidateCancel').off().on('click', function() {
                                $('#joinModal').modal('hide');
                            });
                        });

                        var voteButton = $("<button class='btn btn-success btn-vote'>Vote</button>");
                        voteButton.data("voteIndex", i);
                        row.append($("<td>").append(voteButton));

                        voteButton.click(function() {
                            var voteIndex = $(this).data("voteIndex");

                            App.getCandidates(instance, voteIndex).then(function (candidates) {
                                var candidatesList = $('#candidatesList');
                                candidatesList.empty();
                                console.log(candidates);
                                candidates.forEach(function(candidate, index) {
                                    candidatesList.append(
                                        '<div class="form-check">' +
                                        '<input class="form-check-input" type="checkbox" value=' + index + ' id="candidate' + index + '">' +
                                        '<label class="form-check-label" for="candidate' + index + '">' + candidate + '</label>' +
                                        '</div>'
                                    );
                                });

                                $('#voteModal').modal('show');

                                $('#voteConfirm').off().on('click', function() {
                                    var selectedCandidates = [];
                                    var selectedIndexes = [];
                                    $('#candidatesList input:checked').each(function() {
                                        selectedCandidates.push($(this).val());
                                        selectedIndexes.push($(this).data('index'));
                                    });

                                    $('#voteModal').modal('hide');
                                    console.log('Vote Index:', voteIndex);
                                    console.log('Selected Candidates:', selectedCandidates);
                                    console.log('Selected Indexes:', selectedIndexes);

                                    if (selectedCandidates.length > 0) {
                                        var selectedIndex = selectedCandidates[0]; // 只传递第一个选中的候选人的索引
                                        console.log(selectedIndex);
                                        App.contracts.Voting.deployed().then(function (instance) {
                                          return instance.vote(voteIndex, selectedIndex, { from: web3.eth.accounts[0] })
                                        });
                                        console.log("ok");
                                    }
                                });
                            });
                        });

                        let endButton = $("<button id='end' class='btn btn-primary btn-join'>End</button>");
                        endButton.data("voteIndex", i);
                        row.append($("<td>").append(endButton));

                        endButton.click(function() {
                          var index = $(this).data("voteIndex");
                          console.log(index);
                          App.contracts.Voting.deployed().then(function (instance) {
                            instance.endVote(index, { from: web3.eth.accounts[0] });
                          })
                        });

                        votesTable.append(row);
                    }
                });
            });
        });
    }).catch(function (error) {
        console.error("Error fetching votes:", error);
    });
  },


  displayClosedVotes: function () {
    let votesTable = $("#historyTable");
    votesTable.empty();

    App.contracts.Voting.deployed().then(function (instance) {
      instance.getVoteNum.call().then(function (total_) {
          var total = total_.toNumber(); // Assuming total_ is a BigNumber object
          console.log("total");
          console.log(total);

          var votePromises = [];
          for (var i = 0; i < total; i++) {
              votePromises.push(instance.getVote.call(i));
          }

          Promise.all(votePromises).then(function (votes) {
              votes.forEach(function (t, i) {
                  console.log(t);

                  var closed = t[0];
                  var creator = t[1];
                  var name = t[2];
                  var endTime = new Date(t[3].toNumber() * 1000).toLocaleString();;
                  var winner = t[4];

                  if (closed) {
                      var row = $("<tr>");
                      row.append("<td>" + name + "</td>");
                      row.append("<td>" + creator + "</td>");
                      row.append("<td>" + winner + "</td>");

                      
                      votesTable.append(row);
                  }
              });
          });
      });
  }).catch(function (error) {
      console.error("Error fetching votes:", error);
  });
  },

  displayTransactionHashes() {
    App.contracts.Voting.deployed().then(function (instance) {
      instance.getTransactionHashes.call().then(function (hashes) {
        console.log(hashes);

        // 确保哈希是一个数组
        if (!Array.isArray(hashes)) {
            hashes = Object.values(hashes);
        }

        // 显示哈希
        const ul = document.getElementById("transactionHashes");
        ul.innerHTML = ""; // 清空之前的哈希列表
        hashes.forEach(hash => {
            const li = document.createElement("li");
            li.textContent = hash;
            ul.appendChild(li);
        });
      });
      
    })
    
}
};

$(function () {
  $(window).load(function () {
    App.init();
  });
});
