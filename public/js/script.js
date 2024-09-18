
// Kör då det laddats in
document.addEventListener("DOMContentLoaded", () => {
        
    // Hämta kort-data från elementet, sedan ta bort elementet
    const data_elem = document.getElementById("data");
    const game_data = JSON.parse(data_elem.dataset.json);
    data_elem.remove();

    // Timer-variabler
    let timer_value = 0.0;
    const timer_elem = document.getElementById("timer");
    const pause_length = 900;

    // Kort-element
    const card_section_elem = document.getElementById("section-card");
    const card_template_html = card_section_elem.innerHTML;

    // Poäng-span
    const score_span = document.querySelector('span#current-score');

    // Egen, simpel funktion för omdiregering av användaren
    function redirect(destination) {
        window.location.href = '/' + destination;
    }

    // Generera random siffra från noll till och med numret under angivet värde
    function getRandomInt(max) {
        return Math.floor(Math.random() * max);
    }

    // Stoppar in sträng i en annan sträng efter substräng
    function insertAfter(str, substr, insertstr) {
        const index = str.indexOf(substr);
        if(index === -1) {
            console.error("Error.");
            return;
        }
        const pos = index + substr.length
        const result = str.slice(0, pos) + insertstr + str.slice(pos);
        return result;
    }

    // Blanda array
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

    // Formattera datetime till vad databasen vill ha
    function formatDateTime(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0'); // Months are zero-based
        const day = String(date.getDate()).padStart(2, '0');
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const seconds = String(date.getSeconds()).padStart(2, '0');
      
        return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
    }

    // Påbörjar gissning av person; visar upp bild och alternativ, och sätter igång timer
    function showPerson(game_data, i) {

        // Uppdaterar kort-elementets bild och namn
        function showCard(person_data) {
            let card_html = insertAfter(card_template_html, 'src="', person_data['img_url']);
            card_html = insertAfter(card_html, '<label for="card" id="card-name">', person_data['name']);
            card_section_elem.innerHTML = card_html;
        }

        function showOptions(game_data, i) {

            let options = [game_data['people'][i]['name']];
            let gender = game_data['people'][i]['gender'];

            // Plockar ut alla namn som är rätt kön och som inte varit rätt svar än
            let names = game_data['people'].slice(i+1).filter(person => person['gender'] === gender).map(person => person['name']);
            names = names.concat(game_data['herrings'].filter(person => person['gender'] === gender).map(person => person['name'])); 

            // Väljer ut 3 namn till att ha som alternativ, ur names-arrayen
            // Kommer inte bli dups tack vare splice
            let j;
            for(let i=0; i<3; i++) {
                j = getRandomInt(names.length)
                if(!names[j]) {
                    options.push('Thanos');
                } else {
                    options.push(names[j]);
                }
                names.splice(j, 1);
            }

            // Blanda options-array
            shuffle(options);

            // Går genom och uppdaterar alternativ-elementen
            Array.from(document.querySelectorAll("#list-options > .option")).forEach((option_elem, index) => {
                // Återställer elementen till matchande färg
                option_elem.classList.remove('correct');
                option_elem.classList.remove('incorrect');
                // Skriver det nya namnet
                option_elem.textContent = options[index]

                // Gör alternativen klickbara
                // Kör chooseOption vid klick
                const handleChoice = () => {
                    chooseOption(option_elem.textContent, game_data, i);
                }
                option_elem.addEventListener('click', handleChoice);
            });
        }

        showCard(game_data['people'][i]);
        showOptions(game_data, i);

        // Aktiverar 
        timer_value = 0.0;
        timer = setInterval(() => {
            timer_elem.innerHTML = String(timer_value.toFixed(1));
            timer_value += 0.1;
            if(timer_value >= 10) {
                clearInterval(timer);
                timer_elem.innerHTML = "10 (max)";
            }
        }, 100);
    }

    function sendResult() {
        const final_score = score_span.textContent;
        const date = formatDateTime(new Date());
        
        // Kör post-request med resultatet
        fetch(window.location.href, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ score: final_score, date: date, set_id: game_data['id'] }) // TODO: Osäker, någon kan skicka in vad för poäng som helst
        })
        .then(response => {
            if(!response.ok) {
                throw new Error('Faulty response.');
            }
            return response.json();
        })
        .then(data => {
            // Hantering av respons-data?
            if(data.status == 200 ) {
                redirect("") // Omdiregera till startsida
            } 
        })
        .catch(error => {
            // Hantering av errors?
            console.error(error);
        });
    }

    function chooseOption(guess, game_data, i) {

        function reveal(correct_name) {

            function flipCard() {
                let card_elem = document.getElementById("active-card");
                card_elem.classList.add('flip');
            }

            flipCard();

            // Applicera klass på alternativen som anger vilken som var rätt och vilken som var fel
            // Färg appliceras baserat på klass med CSS
            Array.from(document.querySelectorAll("#list-options > .option")).forEach(option_elem => {
                if(option_elem.textContent !== correct_name) {
                    option_elem.classList.add('incorrect');
                } else {
                    option_elem.classList.add('correct');
                }
            });
        }

        function updateScore(final_time) {
            const previous_total = parseFloat(score_span.textContent);

            // Poäng-system utefter tid, förbättra?
            const new_total = previous_total + (10.0 - final_time);

            score_span.textContent = new_total.toFixed(1);
        }

        // Klonar och ersätter alla alternativ-element för att ta bort event-listeners
        Array.from(document.querySelectorAll("#list-options > .option")).forEach(option_elem => {
            const new_elem = option_elem.cloneNode(true);
            option_elem.parentNode.replaceChild(new_elem, option_elem);
        });

        // Visa rätt svar
        const correct_name = game_data['people'][i]['name'];
        reveal(correct_name);

        // Stäng av timern och spara tiden
        clearInterval(timer);
        const final_time = parseFloat(document.getElementById("timer").textContent);

        if(guess !== correct_name) {
            // Om inkorrekt, avsluta spelet
            pause = setTimeout(() => {
                sendResult();
            }, pause_length);
        } else {
            // Om korrekt, updatera poäng
            updateScore(final_time);
            // Om sista person, avsluta spelet
            if(i >= game_data['people'].length-1) {
                pause = setTimeout(() => {
                    sendResult();
                }, pause_length);
            } else {
                // Fortsätt, index ökar med 1
                pause = setTimeout(() => {
                    showPerson(game_data, i+1);
                }, pause_length);
            }

        }
    }

    function run() {
        // Aktuellt kort-index
        const i = 0;
        showPerson(game_data, i);
    }

    run()

});