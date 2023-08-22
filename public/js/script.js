const data_elem = document.getElementById("data");
const cards_data = JSON.parse(data_elem.dataset.json);

const other_names = [{name:'Pontus Wahlgren', kon:'m'}, {name:'Håkan Persson', kon:'m'}, {name:'Igor Rickardsson', kon:'m'}, {name:'William Fahger', kon:'m'}, {name:'Joel Ramberg Themelis', kon:'m'}]

function redirect(destination) {
    window.location.href = '/' + destination;
}

function getRandomInt(max) {
    return Math.floor(Math.random() * max);
}

function shuffle(array) {
    let currentIndex = array.length, randomIndex;
  
    // While there remain elements to shuffle.
    while(currentIndex != 0) {
  
        // Pick a remaining element.
        randomIndex = Math.floor(Math.random() * currentIndex);
        currentIndex--;
    
        // And swap it with the current element.
        [array[currentIndex], array[randomIndex]] = [array[randomIndex], array[currentIndex]];
    }
  
    return array;
  }

function enterPerson(cards_data, other_names, n) {

    function showCard(person_data) {
        card_html = `<div id="active-card"><div class="card-face front"><img id="card-photo" src="./img/class/${person_data.img}.jpeg" alt="${person_data.name}"></div><div class="card-face back"><label id="card-name" for="card">${person_data.name}</label></div></div>`;
        let card_section_elem = document.getElementById("section-card");
        card_section_elem.innerHTML = card_html;
    }

    function showOptions(cards_data, other_names, n) {

        let options = [cards_data[n-1].name];
        let options_html = "";
        
        let names = []
        names = names.concat(cards_data.slice((n-1), -1));
        names = names.concat(other_names);

        let j;
        for(let i=0; i<3; i++) {
            j = getRandomInt(names.length);
            while(options.includes(names[j].name, 0)) {
                j = getRandomInt(names.length);
            }
            options.push(names[j].name);
            names.splice(j, j);
        }

        shuffle(options);

        options.forEach(option => {
            options_html += `<li class="option">${option}</li>`;
        });

        document.getElementById("list-options").innerHTML = options_html;

        const option_elems = document.querySelectorAll("#list-options > .option");
        option_elems.forEach(option => {
            option.addEventListener('click', () => {
                chooseOption(option.textContent, cards_data, other_names, n);
            });
        });
    }

    if(n > 1) {
        showCard(cards_data[n-1]);
        showOptions(cards_data, other_names, n);
    } else {
        const option_elems = document.querySelectorAll("#list-options > .option");
        option_elems.forEach(option => {
            option.addEventListener('click', () => {
                chooseOption(option.textContent, cards_data, other_names, n);
            });
        });
    }

    var timer_value = 0.0;
    var timer_elem = document.getElementById("timer");
    timer = setInterval(() => {
        timer_value += 0.1;
        timer_elem.innerHTML = String(timer_value.toFixed(1));
        if(timer_value >= 10) {
            clearInterval(timer);
            timer_elem.innerHTML = "10 (max)";
        }
    }, 100);
}

function seeResult() {
    const final_score = document.getElementById("current-score").textContent;
    
    fetch('http://localhost:4567/game', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ score: final_score })
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.json();
    })
    .then(data => {
        // Handle the response data if needed
        console.log(data);
        if (data.status == 200 ){
            redirect("start")
        } 
    })
    .catch(error => {
        // Handle errors here
        console.error(error);
    });
}


function chooseOption(guess, cards_data, other_names, n) {

    function reveal(correct_name) {

        function flipCard() {
            let card_elem = document.getElementById("active-card");
            card_elem.classList.add('flip');
        }

        flipCard();

        const option_elems = document.querySelectorAll("#list-options > .option");
        option_elems.forEach(option => {
            if(option.textContent !== correct_name) {
                option.classList.add('incorrect');
            } else {
                option.classList.add('correct');
            }
        });
    }

    function updateScore(final_time) {
        const previous_total = parseFloat(document.getElementById('current-score').textContent);
        const new_total = previous_total + (10.0-final_time);
        document.getElementById('current-score').innerHTML = String(new_total.toFixed(1));
    }

    let correct_name = cards_data[n-1].name;
    reveal(correct_name);

    var final_time = parseFloat(document.getElementById("timer").textContent);
    clearInterval(timer);
    if(guess !== correct_name) {
        pause = setTimeout(() => {
            seeResult();
        }, 1200);
    } else {
        updateScore(final_time);
        if(n >= cards_data.length) {
            pause = setTimeout(() => {
                seeResult();
            }, 1200);
        }   
        pause = setTimeout(() => {
            enterPerson(cards_data, other_names, n+1);
        }, 1200);
    }
}

enterPerson(cards_data, other_names, 1);