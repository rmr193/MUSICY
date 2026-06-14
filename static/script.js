// DOM Element References
const homeLink = document.getElementById('home-link');
const searchLink = document.getElementById('search-link');
const libraryLink = document.getElementById('library-link');
const sidebarAddPlaylistBtn = document.getElementById('sidebar-add-playlist-btn');
const sidebarPlaylistsList = document.getElementById('sidebar-playlists-list');

const topbarSearchContainer = document.getElementById('topbar-search-container');
const searchInput = document.getElementById('search-input');
const mainViewContainer = document.getElementById('main-view-container');

// Views
const homeView = document.getElementById('home-view');
const searchView = document.getElementById('search-view');
const playlistView = document.getElementById('playlist-view');
const libraryView = document.getElementById('library-view');

// Home View Elements
const welcomeGreeting = document.getElementById('welcome-greeting');
const quickPlayGrid = document.getElementById('quick-play-grid');
const recentSongsGrid = document.getElementById('recent-songs-grid');

// Search View Elements
const resultsList = document.getElementById('results-list');

// Playlist Detail View Elements
const playlistHeaderBg = document.getElementById('playlist-header-bg');
const playlistCoverLarge = document.getElementById('playlist-cover-large');
const playlistDetailName = document.getElementById('playlist-detail-name');
const playlistDetailCount = document.getElementById('playlist-detail-count');
const playlistDetailDuration = document.getElementById('playlist-detail-duration');
const playlistPlayBtn = document.getElementById('playlist-play-btn');
const playlistShuffleBtn = document.getElementById('playlist-shuffle-btn');
const playlistRenameBtn = document.getElementById('playlist-rename-btn');
const playlistDeleteBtn = document.getElementById('playlist-delete-btn');
const playlistTracksList = document.getElementById('playlist-tracks-list');

// Library Grid View Elements
const libraryPlaylistsGrid = document.getElementById('library-playlists-grid');

// Bottom Player Elements
const audioPlayer = document.getElementById('audio-player');
const playPauseBtn = document.getElementById('play-pause-btn');
const prevBtn = document.getElementById('prev-btn');
const nextBtn = document.getElementById('next-btn');
const playIcon = document.getElementById('play-icon');
const playerCover = document.getElementById('player-cover');
const playerTitle = document.getElementById('player-title');
const playerArtist = document.getElementById('player-artist');
const playerLikeBtn = document.getElementById('player-like-btn');
const playerShuffleBtn = document.getElementById('player-shuffle-btn');
const playerRepeatBtn = document.getElementById('player-repeat-btn');
const currentTimeEl = document.getElementById('current-time');
const totalTimeEl = document.getElementById('total-time');
const progress = document.getElementById('progress');
const progressBar = document.querySelector('.progress-bar');
const volumeBtn = document.getElementById('volume-btn');
const volumeProgress = document.getElementById('volume-progress');
const volumeBar = document.querySelector('.volume-bar');

// Modal Elements
const playlistModal = document.getElementById('playlist-modal');
const modalTitle = document.getElementById('modal-title');
const modalInput = document.getElementById('modal-input');
const modalCancel = document.getElementById('modal-cancel');
const modalSubmit = document.getElementById('modal-submit');

// Dropdown Elements
const trackDropdown = document.getElementById('track-dropdown');
const dropdownPlaylistsList = document.getElementById('dropdown-playlists-list');

// Global Application State
let hls = null;
let currentPlayingId = null;
let currentTrack = null;
let activeQueue = [];
let activeQueueIndex = -1;
let currentOpenPlaylistId = null; // ID of the currently displayed playlist
let latestSearchTracks = [];
let searchController = null;

// Playback settings
let isShuffle = false;
let repeatState = 'none'; // 'none', 'all', 'one'
let currentVolume = 1.0;
let isMuted = false;

// Modal Action Callback
let modalCallback = null;

// Storage configuration
const LIBRARY_STORAGE_KEY = 'musicyLibrarySpotify';

// Initialize App State
let library = loadLibrary();

// ----------------------------------------------------
// STATE PERSISTENCE & INITIALIZATION
// ----------------------------------------------------

function loadLibrary() {
    try {
        const stored = localStorage.getItem(LIBRARY_STORAGE_KEY);
        let data = stored ? JSON.parse(stored) : null;
        
        // Structure cleanup and defaulting
        if (!data) {
            data = {
                likedSongs: [],
                playlists: [],
                playedSongs: []
            };
        }
        if (!Array.isArray(data.likedSongs)) data.likedSongs = [];
        if (!Array.isArray(data.playlists)) data.playlists = [];
        if (!Array.isArray(data.playedSongs)) data.playedSongs = [];
        
        return data;
    } catch (err) {
        console.error('Error reading local storage library schema', err);
        return { likedSongs: [], playlists: [], playedSongs: [] };
    }
}

function saveLibrary() {
    try {
        localStorage.setItem(LIBRARY_STORAGE_KEY, JSON.stringify(library));
    } catch (err) {
        console.error('Failed to sync library state to localStorage', err);
    }
}

// ----------------------------------------------------
// APP INITIALIZATION
// ----------------------------------------------------

document.addEventListener('DOMContentLoaded', () => {
    // Set greeting
    updateGreeting();
    
    // Load volume settings
    const savedVol = localStorage.getItem('musicyVolume');
    if (savedVol !== null) {
        currentVolume = parseFloat(savedVol);
        audioPlayer.volume = currentVolume;
        volumeProgress.style.width = `${currentVolume * 100}%`;
    }
    
    // Wire up events
    setupEventListeners();
    
    // Initial Render
    renderSidebar();
    
    // Show Home View by default
    navigateToView('home');
});

// ----------------------------------------------------
// VIEW NAVIGATION & ROUTING
// ----------------------------------------------------

function navigateToView(viewName, arg = null) {
    // Hide all view panels
    homeView.classList.add('hidden');
    searchView.classList.add('hidden');
    playlistView.classList.add('hidden');
    libraryView.classList.add('hidden');
    
    // De-activate all sidebar nav links
    document.querySelectorAll('.nav-links li').forEach(el => el.classList.remove('active'));
    document.getElementById('library-link').classList.remove('active');
    document.querySelectorAll('.sidebar-playlist-item').forEach(el => el.classList.remove('active'));
    
    // Reset global search bar visibility
    if (viewName === 'search') {
        topbarSearchContainer.style.display = 'block';
        searchLink.closest('li').classList.add('active');
        searchView.classList.remove('hidden');
        renderSearchPlaceholder();
    } else {
        topbarSearchContainer.style.display = 'none';
        
        if (viewName === 'home') {
            homeLink.closest('li').classList.add('active');
            homeView.classList.remove('hidden');
            renderHomeView();
        } else if (viewName === 'library') {
            libraryLink.classList.add('active');
            libraryView.classList.remove('hidden');
            renderLibraryGridView();
        } else if (viewName === 'playlist') {
            playlistView.classList.remove('hidden');
            renderPlaylistDetailView(arg);
        }
    }
    
    // Close dropdowns
    closeDropdown();
}

function updateGreeting() {
    const hr = new Date().getHours();
    let text = "Good day";
    if (hr < 12) text = "Good morning";
    else if (hr < 18) text = "Good afternoon";
    else text = "Good evening";
    welcomeGreeting.textContent = text;
}

// Generates cohesive theme gradient header colors based on title string hash
function getGradientStyle(title) {
    let hash = 0;
    for (let i = 0; i < title.length; i++) {
        hash = title.charCodeAt(i) + ((hash << 5) - hash);
    }
    const h = Math.abs(hash % 360);
    // Dark Spotify-friendly pastel gradients
    const colorStart = `hsl(${h}, 50%, 25%)`;
    const colorEnd = `hsl(${h}, 30%, 8%)`;
    return {
        headerBg: `linear-gradient(180deg, ${colorStart} 0%, rgba(18, 18, 18, 0) 100%)`,
        themeColor: colorStart
    };
}

// ----------------------------------------------------
// UI RENDERING METHODS
// ----------------------------------------------------

function renderSidebar() {
    sidebarPlaylistsList.innerHTML = '';
    
    // 1. Render Liked Songs Sidebar Item
    const likedItem = document.createElement('div');
    likedItem.className = 'sidebar-playlist-item';
    if (currentOpenPlaylistId === 'liked-songs') {
        likedItem.classList.add('active');
    }
    
    const count = library.likedSongs.length;
    likedItem.innerHTML = `
        <div class="sidebar-playlist-artwork liked-songs">
            <i class="fa-solid fa-heart"></i>
        </div>
        <div class="sidebar-playlist-info">
            <div class="sidebar-playlist-name">Liked Songs</div>
            <div class="sidebar-playlist-meta">Playlist • ${count} song${count === 1 ? '' : 's'}</div>
        </div>
    `;
    likedItem.addEventListener('click', () => {
        navigateToView('playlist', 'liked-songs');
    });
    sidebarPlaylistsList.appendChild(likedItem);
    
    // 2. Render Custom Playlists
    library.playlists.forEach(playlist => {
        const item = document.createElement('div');
        item.className = 'sidebar-playlist-item';
        if (currentOpenPlaylistId === playlist.id) {
            item.classList.add('active');
        }
        
        const songCount = playlist.tracks.length;
        
        // Artwork: first song's thumbnail or a default music icon
        let artContent = `<i class="fa-solid fa-music"></i>`;
        if (playlist.tracks.length > 0 && playlist.tracks[0].thumbnail) {
            artContent = `<img src="${playlist.tracks[0].thumbnail}" alt="${playlist.name}">`;
        }
        
        item.innerHTML = `
            <div class="sidebar-playlist-artwork">
                ${artContent}
            </div>
            <div class="sidebar-playlist-info">
                <div class="sidebar-playlist-name">${escapeHTML(playlist.name)}</div>
                <div class="sidebar-playlist-meta">Playlist • ${songCount} song${songCount === 1 ? '' : 's'}</div>
            </div>
        `;
        
        item.addEventListener('click', () => {
            navigateToView('playlist', playlist.id);
        });
        sidebarPlaylistsList.appendChild(item);
    });
}

function renderHomeView() {
    updateGreeting();
    quickPlayGrid.innerHTML = '';
    
    // Quick play list (Liked Songs + first 5 custom playlists)
    const quickList = [];
    quickList.push({
        id: 'liked-songs',
        name: 'Liked Songs',
        isLiked: true,
        tracks: library.likedSongs
    });
    
    library.playlists.slice(0, 5).forEach(pl => {
        quickList.push({
            id: pl.id,
            name: pl.name,
            isLiked: false,
            tracks: pl.tracks
        });
    });
    
    quickList.forEach(item => {
        const card = document.createElement('div');
        card.className = 'quick-play-card';
        
        let coverHtml = '';
        if (item.isLiked) {
            coverHtml = `<div class="quick-play-cover liked-songs"><i class="fa-solid fa-heart"></i></div>`;
        } else {
            const firstTrackArt = item.tracks.length > 0 ? item.tracks[0].thumbnail : '';
            if (firstTrackArt) {
                coverHtml = `<div class="quick-play-cover"><img src="${firstTrackArt}" alt="${item.name}"></div>`;
            } else {
                coverHtml = `<div class="quick-play-cover"><i class="fa-solid fa-music"></i></div>`;
            }
        }
        
        card.innerHTML = `
            ${coverHtml}
            <div class="quick-play-name">${escapeHTML(item.name)}</div>
            <button class="quick-play-btn-overlay" title="Play playlist">
                <i class="fa-solid fa-play"></i>
            </button>
        `;
        
        // Play playlist immediately on play click
        const playOverlayBtn = card.querySelector('.quick-play-btn-overlay');
        playOverlayBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            if (item.tracks.length === 0) {
                alert("Playlist is empty. Add songs to play.");
                return;
            }
            setActiveQueue(item.tracks, 0);
            playTrack(item.tracks[0]);
        });
        
        card.addEventListener('click', () => {
            navigateToView('playlist', item.id);
        });
        
        quickPlayGrid.appendChild(card);
    });
    
    // Recently played tracks
    recentSongsGrid.innerHTML = '';
    if (library.playedSongs.length === 0) {
        recentSongsGrid.innerHTML = `<p class="placeholder-text">Songs you play will appear here.</p>`;
    } else {
        // Show up to 6 recently played song cards
        library.playedSongs.slice(0, 6).forEach((track, index) => {
            const card = document.createElement('div');
            card.className = 'song-card';
            
            card.innerHTML = `
                <div class="song-card-artwork">
                    <img src="${track.thumbnail || 'https://via.placeholder.com/150'}" alt="Cover">
                    <button class="song-card-play-btn" title="Play">
                        <i class="fa-solid fa-play"></i>
                    </button>
                </div>
                <div class="song-card-title">${escapeHTML(track.title)}</div>
                <div class="song-card-artists">${escapeHTML(track.artists)}</div>
            `;
            
            const cardPlayBtn = card.querySelector('.song-card-play-btn');
            cardPlayBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                // Set the played tracks as the current queue starting from this track
                setActiveQueue(library.playedSongs, index);
                playTrack(track);
            });
            
            card.addEventListener('click', () => {
                // Clicking song card plays it and sets queue
                setActiveQueue(library.playedSongs, index);
                playTrack(track);
            });
            
            recentSongsGrid.appendChild(card);
        });
    }
}

function renderLibraryGridView() {
    libraryPlaylistsGrid.innerHTML = '';
    
    const items = [
        { id: 'liked-songs', name: 'Liked Songs', isLiked: true, tracks: library.likedSongs }
    ];
    library.playlists.forEach(pl => {
        items.push({ id: pl.id, name: pl.name, isLiked: false, tracks: pl.tracks });
    });
    
    items.forEach(item => {
        const card = document.createElement('div');
        card.className = 'song-card'; // Reuse song card styling
        
        let coverHtml = '';
        if (item.isLiked) {
            coverHtml = `<div class="quick-play-cover liked-songs" style="width: 100%; height: 100%; position: absolute; top:0; left:0; display:flex; align-items:center; justify-content:center; font-size:48px;"><i class="fa-solid fa-heart"></i></div>`;
        } else {
            const firstTrackArt = item.tracks.length > 0 ? item.tracks[0].thumbnail : '';
            if (firstTrackArt) {
                coverHtml = `<img src="${firstTrackArt}" alt="${item.name}" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; object-fit: cover;">`;
            } else {
                coverHtml = `<div style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; background: linear-gradient(135deg, #2c3e50, #3498db); display:flex; align-items:center; justify-content:center; font-size:48px; color:#fff;"><i class="fa-solid fa-music"></i></div>`;
            }
        }
        
        card.innerHTML = `
            <div class="song-card-artwork">
                ${coverHtml}
                <button class="song-card-play-btn" title="Play">
                    <i class="fa-solid fa-play"></i>
                </button>
            </div>
            <div class="song-card-title">${escapeHTML(item.name)}</div>
            <div class="song-card-artists">Playlist • ${item.tracks.length} track${item.tracks.length === 1 ? '' : 's'}</div>
        `;
        
        card.querySelector('.song-card-play-btn').addEventListener('click', (e) => {
            e.stopPropagation();
            if (item.tracks.length === 0) {
                alert("Playlist is empty!");
                return;
            }
            setActiveQueue(item.tracks, 0);
            playTrack(item.tracks[0]);
        });
        
        card.addEventListener('click', () => {
            navigateToView('playlist', item.id);
        });
        
        libraryPlaylistsGrid.appendChild(card);
    });
}

function renderSearchPlaceholder() {
    resultsList.innerHTML = `<p class="placeholder-text">Type in the search box to find songs...</p>`;
}

function renderSearchResults(tracks) {
    resultsList.innerHTML = '';
    if (!tracks || tracks.length === 0) {
        resultsList.innerHTML = `<p class="placeholder-text">No results found.</p>`;
        return;
    }
    
    tracks.forEach((track, index) => {
        const item = createTrackRowItem(track, index + 1, {
            onPlay: () => {
                setActiveQueue(latestSearchTracks, index);
                playTrack(track);
            },
            context: 'search'
        });
        resultsList.appendChild(item);
    });
}

function renderPlaylistDetailView(playlistId) {
    currentOpenPlaylistId = playlistId;
    
    let playlistName = "";
    let trackList = [];
    let isLikedSongs = false;
    
    if (playlistId === 'liked-songs') {
        playlistName = "Liked Songs";
        trackList = library.likedSongs;
        isLikedSongs = true;
    } else {
        const pl = library.playlists.find(p => p.id === playlistId);
        if (!pl) {
            // Fallback to Home if not found
            navigateToView('home');
            return;
        }
        playlistName = pl.name;
        trackList = pl.tracks;
    }
    
    // 1. Render Header information
    playlistDetailName.textContent = playlistName;
    const count = trackList.length;
    playlistDetailCount.textContent = `${count} song${count === 1 ? '' : 's'}`;
    
    // Estimate playlist total duration
    let totalSecs = 0;
    trackList.forEach(t => {
        totalSecs += t.duration_seconds || 0;
    });
    const totalMins = Math.round(totalSecs / 60);
    playlistDetailDuration.textContent = `${totalMins} min`;
    
    // Style Background and Header Color
    const gradient = getGradientStyle(playlistName);
    playlistHeaderBg.style.background = gradient.headerBg;
    
    // Large cover
    if (isLikedSongs) {
        playlistCoverLarge.className = "playlist-cover-large liked-songs";
        playlistCoverLarge.innerHTML = `<i class="fa-solid fa-heart"></i>`;
    } else {
        playlistCoverLarge.className = "playlist-cover-large";
        if (trackList.length > 0 && trackList[0].thumbnail) {
            playlistCoverLarge.innerHTML = `<img src="${trackList[0].thumbnail}" alt="Cover">`;
        } else {
            playlistCoverLarge.innerHTML = `<i class="fa-solid fa-music"></i>`;
        }
    }
    
    // Hide controls accordingly (Rename/Delete only for custom playlists)
    if (isLikedSongs) {
        playlistRenameBtn.style.display = 'none';
        playlistDeleteBtn.style.display = 'none';
    } else {
        playlistRenameBtn.style.display = 'flex';
        playlistDeleteBtn.style.display = 'flex';
    }
    
    // Refresh Sidebar Highlights
    renderSidebar();
    
    // 2. Render playlist tracks list
    playlistTracksList.innerHTML = '';
    if (trackList.length === 0) {
        playlistTracksList.innerHTML = `<div class="placeholder-text" style="padding: 24px;">This playlist has no songs yet. Search and play songs, or add them here!</div>`;
        return;
    }
    
    trackList.forEach((track, index) => {
        const item = createTrackRowItem(track, index + 1, {
            onPlay: () => {
                setActiveQueue(trackList, index);
                playTrack(track);
            },
            onRemove: () => {
                removeTrackFromPlaylist(playlistId, track.videoId);
            },
            context: 'playlist',
            playlistId: playlistId
        });
        playlistTracksList.appendChild(item);
    });
    
    // Add event handlers for playlist actions
    playlistPlayBtn.onclick = () => {
        if (trackList.length === 0) return;
        setActiveQueue(trackList, 0);
        playTrack(trackList[0]);
    };
    
    playlistShuffleBtn.onclick = () => {
        if (trackList.length === 0) return;
        playShuffled(trackList);
    };
    
    playlistRenameBtn.onclick = () => {
        showPlaylistRenameModal(playlistId, playlistName);
    };
    
    playlistDeleteBtn.onclick = () => {
        if (confirm(`Are you sure you want to delete the playlist "${playlistName}"?`)) {
            deletePlaylist(playlistId);
        }
    };
}

// ----------------------------------------------------
// TRACK ROW BUILDER
// ----------------------------------------------------

function createTrackRowItem(track, displayIndex, options = {}) {
    const isCurrentPlaying = (currentPlayingId === track.videoId);
    const isLiked = isTrackLiked(track.videoId);
    
    const row = document.createElement('div');
    row.className = 'track-item';
    if (isCurrentPlaying) {
        row.classList.add('playing');
    }
    
    const displayDuration = track.duration || formatDuration(track.duration_seconds);
    const albumName = track.album || "Single";
    
    row.innerHTML = `
        <div class="col-index track-item-index">
            <span>${displayIndex}</span>
            <i class="fa-solid fa-play play-row-icon"></i>
        </div>
        <div class="col-title" style="display:flex; align-items:center;">
            <img src="${track.thumbnail || 'https://via.placeholder.com/45'}" alt="Cover" loading="lazy">
            <div class="track-info-list">
                <div class="track-title">${escapeHTML(track.title)}</div>
                <div class="track-artist-list">${escapeHTML(track.artists)}</div>
            </div>
        </div>
        <div class="col-album track-album-column">${escapeHTML(albumName)}</div>
        <div class="col-duration track-duration">${displayDuration}</div>
        <div class="col-actions">
            <div class="track-actions">
                <button class="track-action-btn like-row-btn ${isLiked ? 'liked' : ''}" title="${isLiked ? 'Unlike' : 'Like'}">
                    <i class="${isLiked ? 'fa-solid' : 'fa-regular'} fa-heart"></i>
                </button>
                <button class="track-action-btn add-to-playlist-row-btn" title="Add to Playlist">
                    <i class="fa-solid fa-plus"></i>
                </button>
                ${options.context === 'playlist' && options.playlistId !== 'liked-songs' ? `
                    <button class="track-action-btn remove-row-btn" title="Remove from playlist">
                        <i class="fa-solid fa-trash-can"></i>
                    </button>
                ` : ''}
            </div>
        </div>
    `;
    
    // Play row on double click or click play icon
    const indexCol = row.querySelector('.track-item-index');
    indexCol.addEventListener('click', (e) => {
        e.stopPropagation();
        options.onPlay();
    });
    
    row.addEventListener('dblclick', () => {
        options.onPlay();
    });
    
    // Toggle Like from Row
    const likeBtn = row.querySelector('.like-row-btn');
    likeBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        toggleLikeSong(track);
        // Toggle visual
        const currentlyLiked = isTrackLiked(track.videoId);
        likeBtn.className = `track-action-btn like-row-btn ${currentlyLiked ? 'liked' : ''}`;
        likeBtn.querySelector('i').className = `${currentlyLiked ? 'fa-solid' : 'fa-regular'} fa-heart`;
        likeBtn.title = currentlyLiked ? 'Unlike' : 'Like';
    });
    
    // Add to Custom Playlist Trigger
    const addBtn = row.querySelector('.add-to-playlist-row-btn');
    addBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        openAddToPlaylistDropdown(e, track);
    });
    
    // Remove Track (only if on playlist context)
    if (options.onRemove) {
        const removeBtn = row.querySelector('.remove-row-btn');
        if (removeBtn) {
            removeBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                options.onRemove();
            });
        }
    }
    
    return row;
}

// ----------------------------------------------------
// PLAYBACK MECHANICS & AUDIO ENGINE
// ----------------------------------------------------

async function playTrack(track) {
    if (!track.videoId) return;
    const normalized = normalizeTrack(track);
    currentTrack = normalized;
    currentPlayingId = normalized.videoId;
    
    // Auto-add played song to "Liked Songs" playlist as requested!
    addTrackToLikedSongs(normalized);
    
    // Add to recently played
    savePlayedTrack(normalized);
    
    // Redraw components to show playing states
    updatePlayerUI('loading');
    
    let streamUrl = '';
    try {
        const response = await fetch(`/songs/stream/?videoId=${normalized.videoId}`);
        if (!response.ok) {
            throw new Error(`HTTP stream status: ${response.status}`);
        }
        const data = await response.json();
        streamUrl = data.stream_url;
    } catch (err) {
        console.error("Error fetching stream url", err);
        updatePlayerUI('error');
        alert("Unable to fetch audio stream for this track.");
        return;
    }
    
    if (!streamUrl) {
        updatePlayerUI('error');
        alert("No audio stream available.");
        return;
    }
    
    // Update player to ready state
    updatePlayerUI('ready');
    
    // Handle HLS stream vs standard streaming formats
    if (hls) {
        hls.destroy();
        hls = null;
    }
    
    const isHls = streamUrl.includes('.m3u8');
    if (typeof Hls !== 'undefined' && Hls.isSupported() && isHls) {
        hls = new Hls({
            enableWorker: true,
            lowLatencyMode: false
        });
        hls.loadSource(streamUrl);
        hls.attachMedia(audioPlayer);
        hls.on(Hls.Events.MANIFEST_PARSED, function () {
            audioPlayer.play().catch(e => console.log("HLS play deferred", e));
        });
    } else if (isHls && audioPlayer.canPlayType('application/vnd.apple.mpegurl')) {
        // Safari native support
        audioPlayer.src = streamUrl;
        audioPlayer.addEventListener('loadedmetadata', function () {
            audioPlayer.play().catch(e => console.log("Native HLS play deferred", e));
        }, { once: true });
    } else {
        // Fallback for mp3, m4a, etc.
        audioPlayer.src = streamUrl;
        audioPlayer.play().catch(e => console.log("Standard play deferred", e));
    }
    
    // Refresh rows so currently playing turns green
    if (currentOpenPlaylistId) {
        renderPlaylistDetailView(currentOpenPlaylistId);
    }
    if (resultsViewActive()) {
        renderSearchResults(latestSearchTracks);
    }
    renderHomeView();
}

function updatePlayerUI(state) {
    if (!currentTrack) return;
    
    playerCover.src = currentTrack.thumbnail || 'https://via.placeholder.com/56';
    playerCover.style.display = 'block';
    playerArtist.textContent = currentTrack.artists || 'Unknown Artist';
    
    playerLikeBtn.style.display = 'flex';
    const liked = isTrackLiked(currentTrack.videoId);
    playerLikeBtn.className = `player-like-btn ${liked ? 'liked' : ''}`;
    playerLikeBtn.querySelector('i').className = `${liked ? 'fa-solid' : 'fa-regular'} fa-heart`;
    
    if (state === 'loading') {
        playerTitle.textContent = "Loading stream...";
    } else if (state === 'error') {
        playerTitle.textContent = "Error loading song";
    } else {
        playerTitle.textContent = currentTrack.title || 'Unknown Title';
    }
}

function updatePlayIconState(isPlaying) {
    if (isPlaying) {
        playIcon.classList.remove('fa-circle-play');
        playIcon.classList.add('fa-circle-pause');
        playPauseBtn.title = "Pause";
    } else {
        playIcon.classList.remove('fa-circle-pause');
        playIcon.classList.add('fa-circle-play');
        playPauseBtn.title = "Play";
    }
}

function setActiveQueue(tracks, index) {
    activeQueue = tracks.map(t => normalizeTrack(t));
    activeQueueIndex = index >= 0 ? index : 0;
}

function playQueueOffset(offset) {
    if (!activeQueue.length || activeQueueIndex < 0) return;
    
    let nextIndex = activeQueueIndex;
    
    if (isShuffle && offset > 0) {
        // Pick random track index from queue
        nextIndex = Math.floor(Math.random() * activeQueue.length);
    } else {
        nextIndex = activeQueueIndex + offset;
    }
    
    // Bounds check
    if (nextIndex < 0) {
        // Go to start
        nextIndex = 0;
    } else if (nextIndex >= activeQueue.length) {
        // Go to start of queue if repeat all, otherwise stop
        if (repeatState === 'all') {
            nextIndex = 0;
        } else {
            return;
        }
    }
    
    activeQueueIndex = nextIndex;
    const nextTrack = activeQueue[activeQueueIndex];
    playTrack(nextTrack);
}

// Play songs shuffled
function playShuffled(tracks) {
    if (!tracks.length) return;
    // Set queue as copy of tracks
    setActiveQueue(tracks, -1);
    
    // Pick random song to start
    const startIdx = Math.floor(Math.random() * tracks.length);
    activeQueueIndex = startIdx;
    
    // Force shuffle mode visually
    isShuffle = true;
    playerShuffleBtn.classList.add('active');
    
    playTrack(activeQueue[startIdx]);
}

// ----------------------------------------------------
// PLAYLIST CRUD & OPERATIONS
// ----------------------------------------------------

function createPlaylist(name) {
    const trimmed = name.trim();
    if (!trimmed) return;
    
    const newId = `playlist-${Date.now()}`;
    const newPlaylist = {
        id: newId,
        name: trimmed,
        tracks: []
    };
    
    library.playlists.push(newPlaylist);
    saveLibrary();
    renderSidebar();
    
    // Switch to the new playlist detail view immediately
    navigateToView('playlist', newId);
}

function renamePlaylist(playlistId, newName) {
    const trimmed = newName.trim();
    if (!trimmed) return;
    
    if (playlistId === 'liked-songs') return;
    
    const playlist = library.playlists.find(p => p.id === playlistId);
    if (!playlist) return;
    
    playlist.name = trimmed;
    saveLibrary();
    
    // Re-render
    renderSidebar();
    renderPlaylistDetailView(playlistId);
}

function deletePlaylist(playlistId) {
    if (playlistId === 'liked-songs') return;
    
    library.playlists = library.playlists.filter(p => p.id !== playlistId);
    saveLibrary();
    
    if (currentOpenPlaylistId === playlistId) {
        currentOpenPlaylistId = null;
        navigateToView('home');
    } else {
        renderSidebar();
    }
}

function addTrackToPlaylist(playlistId, track) {
    const normalized = normalizeTrack(track);
    
    if (playlistId === 'liked-songs') {
        addTrackToLikedSongs(normalized);
        return;
    }
    
    const playlist = library.playlists.find(p => p.id === playlistId);
    if (!playlist) return;
    
    // Check if song already exists in playlist to avoid duplicates
    const exists = playlist.tracks.some(t => t.videoId === normalized.videoId);
    if (!exists) {
        playlist.tracks.push(normalized);
        saveLibrary();
        renderSidebar();
        
        // Refresh details if currently viewing this playlist
        if (currentOpenPlaylistId === playlistId) {
            renderPlaylistDetailView(playlistId);
        }
    }
}

function removeTrackFromPlaylist(playlistId, videoId) {
    if (playlistId === 'liked-songs') {
        library.likedSongs = library.likedSongs.filter(t => t.videoId !== videoId);
        saveLibrary();
        
        if (currentOpenPlaylistId === 'liked-songs') {
            renderPlaylistDetailView('liked-songs');
        }
        
        // Update player like button visual if current song was unliked
        if (currentTrack && currentTrack.videoId === videoId) {
            updatePlayerUI('ready');
        }
        return;
    }
    
    const playlist = library.playlists.find(p => p.id === playlistId);
    if (!playlist) return;
    
    playlist.tracks = playlist.tracks.filter(t => t.videoId !== videoId);
    saveLibrary();
    renderSidebar();
    
    if (currentOpenPlaylistId === playlistId) {
        renderPlaylistDetailView(playlistId);
    }
}

// ----------------------------------------------------
// LIKED SONGS & TRACK LOGIC
// ----------------------------------------------------

function isTrackLiked(videoId) {
    return library.likedSongs.some(t => t.videoId === videoId);
}

function addTrackToLikedSongs(track) {
    const normalized = normalizeTrack(track);
    const alreadyLiked = isTrackLiked(normalized.videoId);
    
    if (!alreadyLiked) {
        // Insert at first index (most recent like at the top)
        library.likedSongs.unshift(normalized);
        saveLibrary();
        renderSidebar();
        
        if (currentOpenPlaylistId === 'liked-songs') {
            renderPlaylistDetailView('liked-songs');
        }
    }
}

function toggleLikeSong(track) {
    const alreadyLiked = isTrackLiked(track.videoId);
    if (alreadyLiked) {
        removeTrackFromPlaylist('liked-songs', track.videoId);
    } else {
        addTrackToLikedSongs(track);
    }
}

function savePlayedTrack(track) {
    if (!track.videoId) return;
    const normalized = normalizeTrack(track);
    
    // Add to start, filter out duplicates from list, cap at 50 recently played
    library.playedSongs = [
        normalized,
        ...library.playedSongs.filter(t => t.videoId !== normalized.videoId)
    ].slice(0, 50);
    saveLibrary();
}

// Helper: Normalize track fields
function normalizeTrack(track) {
    return {
        videoId: track.videoId,
        title: track.title || 'Unknown Title',
        artists: track.artists || 'Unknown Artist',
        thumbnail: track.thumbnail || 'https://via.placeholder.com/45',
        duration: track.duration || '',
        duration_seconds: track.duration_seconds || 0,
        album: track.album || ''
    };
}

// Helper: Check if results view is actively shown
function resultsViewActive() {
    return !searchView.classList.contains('hidden');
}

// ----------------------------------------------------
// MODAL DIALOG CONTROLLER
// ----------------------------------------------------

function showCreatePlaylistModal() {
    modalTitle.textContent = "Create Playlist";
    modalInput.value = "";
    modalInput.placeholder = "My Playlist #1";
    playlistModal.classList.remove('hidden');
    modalInput.focus();
    
    modalCallback = (val) => {
        const name = val.trim() || `My Playlist #${library.playlists.length + 1}`;
        createPlaylist(name);
    };
}

function showPlaylistRenameModal(playlistId, currentName) {
    modalTitle.textContent = "Rename Playlist";
    modalInput.value = currentName;
    modalInput.placeholder = "Enter playlist name";
    playlistModal.classList.remove('hidden');
    modalInput.focus();
    modalInput.select();
    
    modalCallback = (val) => {
        if (val.trim()) {
            renamePlaylist(playlistId, val);
        }
    };
}

function closeModal() {
    playlistModal.classList.add('hidden');
    modalCallback = null;
}

// ----------------------------------------------------
// ADD TO PLAYLIST CONTEXT DROPDOWN MENU
// ----------------------------------------------------

function openAddToPlaylistDropdown(e, track) {
    dropdownPlaylistsList.innerHTML = '';
    
    // Build list of playlists (excl Liked Songs which is added via Heart)
    if (library.playlists.length === 0) {
        dropdownPlaylistsList.innerHTML = `<div class="dropdown-item" style="color:var(--text-muted); cursor:default;">No playlists created.</div>`;
    } else {
        library.playlists.forEach(pl => {
            const item = document.createElement('div');
            item.className = 'dropdown-item';
            item.textContent = pl.name;
            item.addEventListener('click', () => {
                addTrackToPlaylist(pl.id, track);
                closeDropdown();
            });
            dropdownPlaylistsList.appendChild(item);
        });
    }
    
    // Position dropdown near the click event
    trackDropdown.classList.remove('hidden');
    
    // Prevent menu going offscreen
    let x = e.clientX;
    let y = e.clientY;
    
    const menuWidth = 180;
    const menuHeight = 220;
    
    if (x + menuWidth > window.innerWidth) {
        x = window.innerWidth - menuWidth - 10;
    }
    if (y + menuHeight > window.innerHeight) {
        y = window.innerHeight - menuHeight - 10;
    }
    
    trackDropdown.style.left = `${x}px`;
    trackDropdown.style.top = `${y}px`;
}

function closeDropdown() {
    trackDropdown.classList.add('hidden');
}

// ----------------------------------------------------
// GLOBAL EVENT LISTENERS BINDING
// ----------------------------------------------------

function setupEventListeners() {
    // Nav bar links
    homeLink.addEventListener('click', (e) => {
        e.preventDefault();
        navigateToView('home');
    });
    
    searchLink.addEventListener('click', (e) => {
        e.preventDefault();
        navigateToView('search');
    });
    
    libraryLink.addEventListener('click', (e) => {
        e.preventDefault();
        navigateToView('library');
    });
    
    // Add playlist from sidebar
    sidebarAddPlaylistBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        showCreatePlaylistModal();
    });
    
    // Debounce search input
    let timeout = null;
    searchInput.addEventListener('input', (e) => {
        clearTimeout(timeout);
        const query = e.target.value.trim();
        if (query.length > 0) {
            timeout = setTimeout(() => {
                fetchResults(query);
            }, 400);
        } else {
            renderSearchPlaceholder();
        }
    });
    
    // Player controls play/pause
    playPauseBtn.addEventListener('click', () => {
        if (!audioPlayer.src && !hls) return;
        
        if (audioPlayer.paused) {
            audioPlayer.play().catch(err => console.log("Playback error", err));
        } else {
            audioPlayer.pause();
        }
    });
    
    prevBtn.addEventListener('click', () => {
        playQueueOffset(-1);
    });
    
    nextBtn.addEventListener('click', () => {
        playQueueOffset(1);
    });
    
    // Player Heart Like Button
    playerLikeBtn.addEventListener('click', () => {
        if (currentTrack) {
            toggleLikeSong(currentTrack);
            updatePlayerUI('ready');
        }
    });
    
    // Player Shuffle Button
    playerShuffleBtn.addEventListener('click', () => {
        isShuffle = !isShuffle;
        if (isShuffle) {
            playerShuffleBtn.classList.add('active');
        } else {
            playerShuffleBtn.classList.remove('active');
        }
    });
    
    // Player Repeat Button
    playerRepeatBtn.addEventListener('click', () => {
        if (repeatState === 'none') {
            repeatState = 'all';
            playerRepeatBtn.classList.add('active');
            playerRepeatBtn.title = "Repeat queue";
            playerRepeatBtn.innerHTML = '<i class="fa-solid fa-repeat"></i>';
        } else if (repeatState === 'all') {
            repeatState = 'one';
            playerRepeatBtn.classList.add('active');
            playerRepeatBtn.title = "Repeat one track";
            // Custom repeat-one indicator styling via font-awesome
            playerRepeatBtn.innerHTML = '<i class="fa-solid fa-repeat"></i><span style="font-size:8px; position:absolute; top:2px; right:2px; font-weight:800; background:#1db954; color:#000; width:10px; height:10px; border-radius:50%; display:flex; align-items:center; justify-content:center;">1</span>';
        } else {
            repeatState = 'none';
            playerRepeatBtn.classList.remove('active');
            playerRepeatBtn.title = "Repeat";
            playerRepeatBtn.innerHTML = '<i class="fa-solid fa-repeat"></i>';
        }
    });
    
    // Audio player events
    audioPlayer.addEventListener('play', () => updatePlayIconState(true));
    audioPlayer.addEventListener('pause', () => updatePlayIconState(false));
    
    audioPlayer.addEventListener('timeupdate', () => {
        const cur = audioPlayer.currentTime;
        const dur = audioPlayer.duration;
        if (dur && !isNaN(dur)) {
            const pct = (cur / dur) * 100;
            progress.style.width = `${pct}%`;
            progressBar.style.setProperty('--progress-percent', `${pct}%`);
            currentTimeEl.textContent = formatDuration(cur);
            totalTimeEl.textContent = formatDuration(dur);
        }
    });
    
    // Seek progress
    progressBar.addEventListener('click', (e) => {
        if (audioPlayer.duration && !isNaN(audioPlayer.duration)) {
            const w = progressBar.clientWidth;
            const clickX = e.offsetX;
            const dur = audioPlayer.duration;
            audioPlayer.currentTime = (clickX / w) * dur;
        }
    });
    
    // End track event -> triggers next item in queue
    audioPlayer.addEventListener('ended', () => {
        progress.style.width = '0%';
        currentTimeEl.textContent = '0:00';
        
        if (repeatState === 'one') {
            audioPlayer.currentTime = 0;
            audioPlayer.play().catch(e => console.log("Playback loop failed", e));
        } else {
            playQueueOffset(1);
        }
    });
    
    // Volume Control
    volumeBar.addEventListener('click', (e) => {
        const w = volumeBar.clientWidth;
        const clickX = e.offsetX;
        let vol = clickX / w;
        if (vol < 0.05) vol = 0;
        if (vol > 0.95) vol = 1;
        
        currentVolume = vol;
        isMuted = (vol === 0);
        audioPlayer.volume = currentVolume;
        audioPlayer.muted = isMuted;
        
        volumeProgress.style.width = `${vol * 100}%`;
        localStorage.setItem('musicyVolume', vol);
        updateVolumeIcon();
    });
    
    volumeBtn.addEventListener('click', () => {
        isMuted = !isMuted;
        audioPlayer.muted = isMuted;
        updateVolumeIcon();
    });
    
    // Modal controls
    modalCancel.addEventListener('click', closeModal);
    modalSubmit.addEventListener('click', () => {
        if (modalCallback) {
            modalCallback(modalInput.value);
        }
        closeModal();
    });
    modalInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            if (modalCallback) {
                modalCallback(modalInput.value);
            }
            closeModal();
        } else if (e.key === 'Escape') {
            closeModal();
        }
    });
    
    // Close context dropdowns on click outside
    document.addEventListener('click', () => {
        closeDropdown();
    });
}

function updateVolumeIcon() {
    const icon = volumeBtn.querySelector('i');
    if (isMuted || currentVolume === 0) {
        icon.className = 'fa-solid fa-volume-xmark';
        volumeProgress.style.width = '0%';
    } else {
        volumeProgress.style.width = `${currentVolume * 100}%`;
        if (currentVolume < 0.3) {
            icon.className = 'fa-solid fa-volume-off';
        } else if (currentVolume < 0.7) {
            icon.className = 'fa-solid fa-volume-low';
        } else {
            icon.className = 'fa-solid fa-volume-high';
        }
    }
}

// ----------------------------------------------------
// MUSIC RETRIEVAL API
// ----------------------------------------------------

async function fetchResults(query) {
    try {
        if (searchController) {
            searchController.abort();
        }
        
        searchController = new AbortController();
        resultsList.innerHTML = `<p class="placeholder-text">Searching for "${escapeHTML(query)}"...</p>`;
        
        const response = await fetch(`/songs/search/?query=${encodeURIComponent(query)}&limit=15`, {
            signal: searchController.signal
        });
        
        if (!response.ok) {
            throw new Error(`Search HTTP failed: ${response.status}`);
        }
        
        const data = await response.json();
        
        if (data && data.length > 0) {
            latestSearchTracks = data.map(t => normalizeTrack(t));
            renderSearchResults(latestSearchTracks);
        } else {
            latestSearchTracks = [];
            resultsList.innerHTML = `<p class="placeholder-text">No results found for "${escapeHTML(query)}".</p>`;
        }
    } catch (err) {
        if (err.name === 'AbortError') return;
        console.error("Error fetching song results", err);
        resultsList.innerHTML = `<p class="placeholder-text">Error loading search results.</p>`;
    }
}

// ----------------------------------------------------
// UTILITY FUNCTIONS
// ----------------------------------------------------

function formatDuration(seconds) {
    if (!seconds) return '0:00';
    const num = parseInt(seconds);
    const mins = Math.floor(num / 60);
    const secs = num % 60;
    return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
}

function escapeHTML(str) {
    if (!str) return '';
    return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}
