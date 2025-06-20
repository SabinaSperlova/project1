# SQL dotaz pro vyplnění dat do vzoru kupní smlouvy na byt

Tento projekt obsahuje ukázku SQL dotazu, který připravuje strukturovaná data pro automatické vyplnění vzoru kupní smlouvy na byt. Dotaz slouží k propojení informací o klientovi, konkrétní nemovitosti (bytové jednotce), projektu a parametrech smlouvy, které jsou následně využity ve formátu Word.

## Kontext

Dotaz byl použit v produkčním prostředí pro realitní/developerskou společnost a sloužil jako zdroj dat pro generování individuálních kupních smluv. Výstupem je jedna řádka na jednu smlouvu, ve které jsou předvyplněny klíčové údaje.

## Obsah

- `query.sql` – anonymizovaná a zobecněná verze SQL dotazu
- `README.md` – popis projektu

## Co dotaz dělá

- Sbírá data z velkého množství tabulek (např. `obchodni_pripad`, `byt`, `lokalita`, `partner`, `pozemek`, `parkovaci_stani`, aj.).
- Zajišťuje **datové transformace a formátování** (např. převody datumů, výpočet podílů, rozpoznání typu financování, rozpad podlaží, atd.).
- Generuje dynamické texty pro části smlouvy, např. ohledně **předání jednotky**, **příloh**, **katastrálních údajů** nebo podmínek financování.
- Vytváří sloupce, které dle podmínek nabývají hodnota ANO/NE dle kterých se v šabloně zobrazují / skrývají určité věty i odstavce

## Klíčové prvky dotazu

- **CASE** a **COALESCE** logika pro bezpečné zpracování podmínek
- **String aggregace** pro příslušenství bytu
- **Regulární výrazy** pro extrakci části textu z poznámek a HTML
- **Poddotazy** s `GROUP BY` pro výpočet výměr balkonů, teras, předzahrádek apod.


## Poznámky

- Data byla v projektu vyplňována do šablony kupní smlouvy pomocí robota postaveném na Power Automate.
- Skutečná jména tabulek, sloupců a struktura byla upravena z důvodu ochrany dat.
- Projekt slouží jako demonstrace praktického použití SQL pro automatizaci právních dokumentů.
