"""Hand-authored broad silhouettes for subjects missing from the vector library."""
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
DRAWINGS={
 'typewriter': '<path d="M5 13V3h18v10h3v4l2 12H1l2-12v-4z"/><path fill="black" d="M7 5h14v7H7zM5 20h3v2H5zm5 0h3v2h-3zm5 0h3v2h-3zm5 0h3v2h-3zM4 24h4v2H4zm6 0h3v2h-3zm5 0h3v2h-3zm5 0h5v2h-5z"/>',
 'gramophone': '<path d="M11 4L26 2v15L11 13H8v6h5v3h12v9H3v-9h7v-2H5V8h6z"/><path fill="black" d="M20 5h3v9h-3zM6 25h16v3H6z"/>',
 'printing-press': '<path d="M4 2h19v4H4zM5 6h3v18H5zm15 0h3v18h-3zM12 6h4v9h-4zM9 14h10v4H9zM4 21h20v4H4zM2 28h25v3H2zM5 25h3v3H5zm15 0h3v3h-3z"/><circle cx="24" cy="13" r="4"/><circle cx="24" cy="13" r="1.6" fill="black"/>',
 'oil-lamp': '<path d="M7 18h15l-2 7H9zM12 25h5v3h7v3H5v-3h7zM9 17l2-11h7l2 11z"/><path d="M14 1c-7 7-5 12 0 13 5-2 6-7 0-13z"/><path fill="black" d="M12 8h4v7h-4z"/>',
 'water-jug': '<path d="M11 2h8v5l-3 3v3c8 3 8 13 4 17H8c-5-5-4-14 3-17V9L8 5z"/><path d="M18 7h6c6 0 6 11 1 13h-4v-3h3c3-2 3-7 0-7h-6z"/>',
 'balance-scale': '<path d="M13 2h3v24h7v5H6v-5h7V8H3V5h23v3H16z"/><path d="M4 8h2v6H4zM1 15h9l-2 6H3zM23 8h2v6h-2zM19 15h9l-2 6h-5z"/>',
 'crutches': '<path d="M3 2h10v3H3zM4 5h2v10h4V5h2v12H9v13H6V17H4zM16 2h10v3H16zM17 5h2v10h4V5h2v12h-3v13h-3V17h-2z"/>',
 'cell': '<ellipse cx="14" cy="16" rx="12" ry="14"/><ellipse cx="14" cy="16" rx="9" ry="11" fill="black"/><ellipse cx="15" cy="15" rx="5" ry="6"/><path d="M5 19h3v5H5zM18 24h4v2h-4zM8 7h5v2H8z"/>',
 'bacteria': '<path d="M8 4c-7 4-8 17-3 23 4 5 10 4 13 0 5-7 5-17 0-22-3-3-7-3-10-1z"/><path fill="black" d="M8 9h3v4H8zm7 9h3v4h-3zm-7 4h3v3H8z"/><path d="M3 4H1v3h3zm17 2h6v3h-6zm1 18h6v3h-6z"/>',
 'geode': '<path d="M8 3h13l6 8-1 14-7 6H7L2 23V10z"/><path fill="black" d="M9 7h9l5 6-2 12-11 3-5-8 1-9z"/><path d="M7 13l4-3 2 7-3 6H7zm8-4h4l1 9-4 8-3-4z"/>',
 'pelican': '<path d="M5 23c-2-6 2-12 8-11 4-1 5-4 4-7 0-4 7-4 7 0v5l5 4H19v4c7 7 2 11-10 10H2z"/><path d="M9 27h3v4h-3zm7-1h3v5h-3z"/><path fill="black" d="M21 4h2v2h-2zM7 19h8v3H7z"/>',
 'woodpecker': '<path d="M20 2h6v29h-6zM10 9L15 3l4 5 3 3-5 2-2 7-8 6-5 4 2-10z"/><path fill="black" d="M13 9h2v2h-2zM8 15h3v6H8z"/>',
 'wardrobe': '<path d="M4 2h21v27H4zM5 29h4v2H5zm15 0h4v2h-4z"/><path fill="black" d="M13 4h2v23h-2zM10 15h2v4h-2zm6 0h2v4h-2z"/>',
 'toilet': '<path d="M17 2h9v14h-9zM3 16h22v5l-8 4 3 6H5l4-6-6-4z"/><path fill="black" d="M6 18h15v2H6zM20 5h3v2h-3z"/>',
 'garden-bench': '<path d="M3 7h23v4H3zm0 6h23v4H3zM1 20h27v4H1zM4 17h3v3H4zm17 0h3v3h-3zM4 24h3v7H4zm17 0h3v7h-3z"/>',
 'rocking-horse': '<path d="M4 16h12l1-10 5-4 3 9-3 3v10h-3v-4H8v5H5zM4 13L1 8v9z"/><path d="M1 26c8 5 18 5 26 0v4c-8 4-18 4-26 0z"/><path fill="black" d="M21 7h2v2h-2z"/>',
 'baguette': '<path d="M3 25L19 3c4-3 9 2 6 6L9 30c-4 3-10-1-6-5z"/><path fill="black" d="M16 8l5 4-2 2-5-4zm-5 7l5 4-2 2-5-4zm-5 7l5 4-2 2-5-4z"/>',
 'rolling-pin': '<path d="M1 14h5v-4h17v4h5v5h-5v4H6v-4H1z"/><path fill="black" d="M8 12h2v9H8z"/>',
 'torii-gate': '<path d="M1 4c9 3 18 3 27 0v4c-9 3-18 3-27 0zM3 12h23v4H3zM6 10h4v21H6zm13 0h4v21h-4z"/>',
}

def main():
    destination=ROOT/'collections/original_vectors'
    destination.mkdir(exist_ok=True)
    for key,drawing in DRAWINGS.items():
        svg='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 29 33" width="290" height="330"><path d="M0 0h29v33H0z"/><g fill="white">'+drawing+'</g></svg>'
        (destination/(key+'.svg')).write_text(svg,encoding='utf-8')
    print(f'{len(DRAWINGS)} original broad vector silhouettes')

if __name__=='__main__': main()
