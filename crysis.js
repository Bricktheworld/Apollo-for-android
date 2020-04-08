var module = document.getElementsByClassName("a-box-inner a-alert-container");
try {
    if (module != null && module[0].innerText == "Due to increased demand, available windows are limited. Please check back later or shop a Whole Foods Market near you.") {
        console.log("need to reload");
        window.location.reload(true);
    }
} catch (e) {
    console.log("playing sound")
    let audio = new Audio("http://soundbible.com/mp3/BOMB_SIREN-BOMB_SIREN-247265934.mp3");
    audio.play();
}