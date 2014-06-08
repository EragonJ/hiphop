$ ->
    # show animations & search the data from TrackSource
    doSearch = (searchVal) ->
        userTracking.event("Search", "organic", searchVal).send()
        $('#sidebar-container li.active').removeClass('active')
        $('#tracklist-container').empty()
        spinner = new Spinner(spinner_opts).spin($('#tracklist-container')[0])
        TrackSource.search(searchVal, ((tracks) ->
            spinner.stop()
            PopulateTrackList(tracks)
        ))

    $('#search-input').autocomplete(
        delay: 100
        messages:
            noResults: ''
            results:  ->
        select: (event, ui) ->
          doSearch(ui.item.value)
        source: (request, response) ->
            searchVal = request.term
            if searchVal
                $.getJSON 'http://www.last.fm/search/autocomplete?q=' + searchVal, (data) ->
                    results = data?.response?.docs
                    foundTracks = []
                    if results
                        results.forEach (eachItem, index) ->
                            # find out the right type of this item
                            if eachItem.track
                              itemType = 'Track'
                              itemValue = eachItem.artist + ' ' + eachItem.track
                            else if eachItem.album
                              itemType = 'Album'
                              itemValue = eachItem.artist + ' ' + eachItem.album
                            else
                              itemType = 'Artist'
                              itemValue = eachItem.artist

                            foundTracks.push
                                type: itemType
                                weight: eachItem.weight
                                label: itemValue
                                value: itemValue

                        # tracks with higher scores will be the first
                        foundTracks.sort (trackA, trackB) ->
                            return trackA.weight < trackB.weight

                    response(foundTracks)
            else
                response([])
    ).data('ui-autocomplete')._renderItem = (ul, item) ->
        # make icon
        iconClass = ''
        switch item.type
          when 'Track' then iconClass = 'fa-music'
          when 'Album' then iconClass = 'fa-folder-open-o'
          when 'Artist' then iconClass = 'fa-group'
        $icon = $('<span>')
        $icon.addClass('fa fa-fw ' + iconClass)

        # make label
        $label = $('<span>')
        $label.text(item.label)

        # make anchor
        $a = $('<a>')
        $a.append($icon)
        $a.append($label)

        return $('<li>').data("item.autocomplete", item).append($a).appendTo(ul)

    $('#search-input').keypress (e) ->
        searchVal = $(@).val()
        if e.which is 13 and searchVal != ''
            doSearch(searchVal)

    $('#tracklist-container').on 'click', '.track-container', ->
        PlayTrack($(@).find('.artist').text(), $(@).find('.title').text(), $(@).find('.cover').attr('data-cover_url_medium'), $(@).find('.cover').attr('data-cover_url_large'))
        $(@).siblings('.playing').removeClass('playing')
        $(@).addClass('playing')
