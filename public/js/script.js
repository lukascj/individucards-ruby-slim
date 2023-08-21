function getRandomInt(max) {
    return Math.floor(Math.random() * max);
}
/**
cardArr{
    card1{
        id: 'db-id',
        img: 'db-img',
        name: 'db-name'
    }
    card2{
        id: 'db-id',
        img: 'db-img',
        name: 'db-name'
    }
    card3{
        id: 'db-id',
        img: 'db-img',
        name: 'db-name'
    }

    ...
    
    card17{
        id: 'db-id',
        img: 'db-img',
        name: 'db-name'
    }
}
//  */

const currentCard = {
    id: 'db-id',
    img: 'db-img',
    name: 'db-name'
}

function optionsCreator(){
    const currentName = currentCard.name
    for (let i = 0; i < 3; i++){
        let name = nameArr[getRandomInt(nameArr)]
    }
}