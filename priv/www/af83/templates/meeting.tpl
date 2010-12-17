<div class="page" id="meeting">
    <section class="large">
        <div class="block info">
            <div class="block-content">
                <p><strong>Meeting's name :</strong> <span>{{meeting_name}}</span></p>
                <!--<p><strong><span>{{meeting_users}}</span> connected users</strong></p>-->
                <p><strong>Description :</strong><span>{{meeting_desc}}</span></p>
                <p class="quit"><a href="#/meeting/{{meeting_name}}/quit">Quit the meeting</a></p>
            </div>
        </div>

        <div class="block tools">
            <div class="block-content files" id="files"></div>
        </div>

    </section>

    <section class="main">
        <article id="chat"></article>
        <article id="video"></article>
        <article id="whiteboard"></article>

        <div id="wheel">
            <p><img src="images/wheel.png" /></p>
        </div>

    </section>

    <section id="replay-mode">
        <div id="replay"></div>
        <div class="toggle-results"></div>
        <div id="search"></div>

        <div id="search-results">
            <div class="ui-search-title">Search results</div>
            <div id="activity"></div>
            <div id="results"></div>
        </div>
    </section>
</div>
