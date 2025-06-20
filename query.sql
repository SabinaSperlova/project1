SELECT DISTINCT 
	pns.pozadavek_id,
	op.obchodni_pripad_id, 
	op.cislo_obp,
	pns.typ_smlouvy_id,
	pa.nazev_klienta, 
	COALESCE(CASE 
		WHEN f.financovani_id IN (63, 68) THEN 'Základní financování'
		WHEN f.financovani_id IN (58, 61, 67) THEN 'Individuální financování'
		WHEN f.financovani_id = 64 THEN 'Úvěrové financování'
		ELSE f.nazev
		END, 'ERROR') AS financovani_hlavicka,
	COALESCE (CASE 
		WHEN f.financovani_id = 58 THEN 'IF odklad'
		WHEN f.financovani_id = 61 THEN 'IF splátky'
		WHEN f.financovani_id = 63 THEN 'ZF'
		WHEN f.financovani_id = 64 AND pnstd.typ_dokument_id = 3 THEN 'ÚF zvýhodněná hypotéka'
		WHEN f.financovani_id = 64 THEN 'ÚF'
		WHEN f.financovani_id = 67 THEN 'IF do předání'
		WHEN f.financovani_id = 68 THEN 'ZF postup výstavby'
		WHEN f.financovani_id = 69 THEN 'SF'
		END, 'ERROR') AS financovani_zapati,
	cvb.jednotka,
	jo.nazev AS lokalita,
	jco.nazev AS cast_obce,
	jl.obchodni_nazev AS obchodni_nazev,
	COALESCE(spolecnost.nazev_klienta, 'ERROR') as spolecnost,
	COALESCE (CASE 
        WHEN POSITION('<br>č.' IN spolecnost.poznamka) > 0 
        THEN SUBSTRING(spolecnost.poznamka FROM 1 FOR POSITION('<br>č.' IN spolecnost.poznamka) - 1) 
        ELSE spolecnost.poznamka 
    END, 'ERROR') AS spolecnost_hlavicka,
    CASE WHEN hlavicka.hlavicka NOT LIKE '%korespondenční%' THEN 
  		(coalesce(
   		(CASE
       	WHEN POSITION('e-mail' IN hlavicka.hlavicka) > 0 THEN
            SUBSTRING(hlavicka.hlavicka FROM 1 FOR POSITION('e-mail' IN hlavicka.hlavicka) - 1)
	   	WHEN POSITION('tel.' IN hlavicka.hlavicka) > 0 THEN
            SUBSTRING(hlavicka.hlavicka FROM 1 FOR POSITION('tel.' IN hlavicka.hlavicka) - 1)
              WHEN POSITION('č. účtu' IN hlavicka.hlavicka) > 0 THEN
            SUBSTRING(hlavicka.hlavicka FROM 1 FOR POSITION('č. účtu' IN hlavicka.hlavicka) - 1)
        ELSE
            hlavicka.hlavicka end), 'ERROR'))
   	else (coalesce(
   		(CASE
       	WHEN POSITION('e-mail' IN hlavicka.hlavicka) > 0 THEN
       		regexp_replace(hlavicka.hlavicka,'e-mail.*?<u>korespondenční', '<u>korespondenční', 'g' ) 
       	WHEN POSITION('tel.' IN hlavicka.hlavicka) > 0 THEN
       		regexp_replace(hlavicka.hlavicka,'tel..*?<u>korespondenční', '<u>korespondenční', 'g' )
       	WHEN POSITION('č. účtu' IN hlavicka.hlavicka) > 0 THEN
       		regexp_replace(hlavicka.hlavicka,'č. účtu.*?<u>korespondenční', '<u>korespondenční', 'g' )
       	ELSE
            hlavicka.hlavicka end), 'ERROR'))END  AS hlavicka,
	COALESCE(to_char(op.datum_podpisu::date, 'DD.MM.YYYY'), 'ERROR') AS datum_podpisu,
	b.byt_id,
	COALESCE(cvb.cislo_bytu::text, 'ERROR') AS cislo_bytu,
	COALESCE(CASE WHEN cvb.atelier = 1 THEN 'nebytová jednotka' ELSE 'bytová jednotka' END, 'ERROR') AS bytova_nebytova,
	COALESCE(CASE WHEN cvb.atelier = 1 THEN 'nebytový prostor - ateliér' ELSE 'byt' END, 'ERROR') AS byt_nebyt,
	COALESCE(CASE WHEN cvb.atelier = 1 THEN 'nebytového prostoru - ateliéru' ELSE 'bytu' END, 'ERROR') AS bytu_nebytu,
	CASE WHEN cvb.adresa_cislo_popisne IS NULL THEN 'rozestavěná ' ELSE '' END AS rozestavena,
	CASE WHEN cvb.adresa_cislo_popisne IS NULL THEN 'rozestavěném ' ELSE '' END AS rozestavenem,
	CASE WHEN cvb.adresa_cislo_popisne IS NOT NULL THEN ' č.p. ' || cvb.adresa_cislo_popisne END AS cislo_popisne, 
	COALESCE(l.katastr, 'ERROR') AS katastralni_uzemi,
	CASE WHEN ps_zkratka.zkratka LIKE 'V%' THEN 'ANO' ELSE 'NE' END AS vps,
	COALESCE(CASE WHEN jo.nazev LIKE '%Praha%' THEN 'Praha' ELSE jo.nazev END, 'ERROR') AS obec,
	COALESCE(
		CASE 
			WHEN bd.parcelni_cisla_pozemku_po_zamereni = '' THEN NULL 
			ELSE 
			regexp_replace(bd.parcelni_cisla_pozemku_po_zamereni, '[^0-9/]+', ' ', 'g')
				 END, 
			'ERROR') AS parcelni_cislo,
		pozemky.parcelni_cisla_pozemky,
		bd.soucasti_jednotek_z_pv AS soucasti_jednotek_pv,
	COALESCE(to_char(bd.datum_prohlaseni_vlastnika::date, 'DD.MM.YYYY'), 'ERROR') AS datum_prohlaseni_vlastnika,
	CASE WHEN (b.datum_kolaudace IS NOT NULL OR b.datum_kolaudace::text != '') AND cvb.adresa_cislo_popisne IS NULL THEN 'ANO' ELSE 'NE' END AS kolaudace_cp,
	CASE 
	   	WHEN jp.zkratka = 'NP0' THEN '1'
	   	WHEN jp.zkratka = 'PP0' THEN '2'
	   	WHEN jp.zkratka IS NULL THEN 'ERROR'
	   	ELSE  regexp_replace(jp.zkratka, '[A-Za-z]', '', 'g') END || '. ' ||
	CASE 
		WHEN jp.zkratka = 'NP0' THEN 'PP' 
		WHEN jp.zkratka IS NULL THEN 'ERROR'
		ELSE regexp_replace(jp.zkratka, '[0-9]', '', 'g') 
		END AS podlazi, 
	COALESCE(cvb.vymera_z_pv::text, 'ERROR') AS byt_vymera,
	COALESCE(round(cvb.vymera_z_pv * 10)::text, 'ERROR') AS podil,
	CASE WHEN bd.jmenovatel_z_pv IS NOT NULL THEN bd.jmenovatel_z_pv::text ELSE 'ERROR' END AS jmenovatel,
	'úložný prostor (sklep) č. ' || sklep.sklep AS sklep,
	ps.ps,
	balkon.vymera AS balkon,
	zatravnena_terasa.vymera  AS zatravnena_terasa,
	terasa.vymera AS terasa,
	lodzie.vymera AS lodzie,
	predzahradka.vymera AS predzahradka_vymera,
	predzahradka.predzahradka_cast, 
	predzahradka.predzahradka_pristupna, 
	predzahradka.pocet_predzahradek,
	predzahradka.predzahradka_priloha,
	predzahradka.katastr_predzahradka,
	predzahradka.parcelni_cislo AS predzahradka_parcelni_cislo,
	zpevnena_plocha.vymera AS zpevnena_plocha,
	COALESCE(
		CASE 
			WHEN coalesce(sklep.sklep, ps.ps, balkon.vymera, zatravnena_terasa.vymera, terasa.vymera, lodzie.vymera, predzahradka.vymera) IS NOT NULL THEN 'ANO' 
			ELSE 'NE' 
		END, 'ERROR') AS prislusenstvi,
	COALESCE(
		CASE 
			WHEN f.financovani_id IN (SELECT financovani_id FROM financovani f WHERE uverove = 0) THEN 'ANO' ELSE 'NE' 
			END, 'ERROR') AS odstavec_fin,
	COALESCE (
		CASE 
			WHEN f.uverove = 1 THEN 'ANO' ELSE 'NE' 
		END, 'ERROR') AS odstavec_fin_uf, 
	COALESCE(
		CASE 
			WHEN op.datum_podpisu::date >= b.datum_kolaudace::date + 90 THEN 'ANO' ELSE 'NE' 
			END, 'ERROR') AS podpis_90_dni_po_kolaudaci,-- pokud proběhl podpis 3 a více měsíců po kolaudaci, ukáže se (odst. 3.5)
	COALESCE (
		CASE 
			WHEN predzahradka.pocet_predzahradek > '1' AND ps_zkratka.zkratka LIKE 'V%' THEN 'jsou její Příloha č. 1: Půdorys příslušných podlaží, Příloha č. 2: Zákres předzahrádek a Příloha č. 3: Zákres VPS.'
			WHEN predzahradka.pocet_predzahradek = '1' AND ps_zkratka.zkratka LIKE 'V%' THEN 'jsou její Příloha č. 1: Půdorys příslušných podlaží, Příloha č. 2: Zákres předzahrádky a Příloha č. 3: Zákres VPS.'
			WHEN predzahradka.byt_id IS NOT NULL THEN 'jsou její Příloha č. 1: Půdorys příslušných podlaží a Příloha č. 2: Zákres předzahrádky.' 
			WHEN ps_zkratka.zkratka LIKE 'V%' THEN 'jsou její Příloha č. 1: Půdorys příslušných podlaží a Příloha č. 2: Zákres VPS.' 
			ELSE 'je její Příloha č. 1: Půdorys příslušných podlaží.' 
		END, 'ERROR') AS prilohy,
	COALESCE(CASE WHEN pa.pravni_forma_id = 1 THEN 'ANO' ELSE 'NE' END, 'ERROR') AS fyzicka_osoba,
	COALESCE(CASE 
		WHEN op.datum_predani IS NOT NULL THEN 'byla Společností Klientovi protokolárně předána před uzavřením'
		ELSE 'bude Společností Klientovi protokolárně předána po uzavření'
		END, 'ERROR') AS predani,
	COALESCE(CASE WHEN op.datum_predani IS NOT NULL THEN ' uzavření této smlouvy' ELSE ', kdy bude Jednotka Klientovi předána' END, 'ERROR') AS katastr_podani,
	CASE WHEN cvb.adresa_cislo_popisne IS NULL THEN ', pro Bytový dům bude vydáno pravomocné kolaudační rozhodnutí a bude mu přiděleno číslo popisné' ELSE '' END AS katastr_cp,
	CASE WHEN (b.datum_kolaudace IS NULL OR b.datum_kolaudace::text = '') THEN 'ANO' ELSE 'NE' END AS zmocneni,
	zpracovatel.email as zpracovatel_email,
	CASE WHEN pa.pravni_forma_id = 3 THEN pa.nazev_klienta END AS nazev_klienta_podpis
FROM pozadavek pns
LEFT JOIN obchodni_pripad op ON op.obchodni_pripad_id = pns.obchodni_pripad_id
LEFT JOIN pozadavek_typ_dokument pnstd ON pns.pozadavek_id = pnstd.pozadavek_id
LEFT JOIN klient pa ON pa.klient_id = op.klient_id
LEFT JOIN casova_verze_byt cvb ON cvb.byt_id = op.byt_id AND cvb.casova_hladina_id = (SELECT casova_hladina_id FROM casova_hladina ch WHERE ch.typ_casove_hladiny_id = 1)
LEFT JOIN byt b ON b.byt_id = op.byt_id 
LEFT JOIN patro p ON p.patro_id = b.patro_id 
LEFT JOIN jv_patro jp ON jp.patro_id = p.patro_id AND jp.jazykova_verze_id = 1
LEFT JOIN bytovy_dum bd ON bd.bytovy_dum_id = p.bytovy_dum_id 
LEFT JOIN lokalita l ON l.lokalita_id = bd.lokalita_id 
LEFT JOIN casova_verze_lokalita cvl ON cvl.lokalita_id = l.lokalita_id AND cvl.casova_hladina_id = (SELECT casova_hladina_id FROM casova_hladina ch WHERE ch.typ_casove_hladiny_id = 1)
LEFT JOIN jv_lokalita jl ON jl.casova_verze_lokalita_id = cvl.casova_verze_lokalita_id AND jl.jazykova_verze_id = 1
LEFT JOIN jv_cast_obce jco ON jco.cast_obce_id = l.cast_obce_id AND jco.jazykova_verze_id = 1
LEFT JOIN jv_obec jo ON jo.obec_id = l.obec_id AND jo.jazykova_verze_id = 1
LEFT JOIN klient spolecnost ON spolecnost.klient_id = l.developer_prodeje_klient_id
LEFT JOIN uzivatel zpracovatel on zpracovatel.uzivatel_id = pns.zpracovava_uzivatel_id 
LEFT JOIN (
	select byt_id, 
		CASE WHEN count(mistnost_id) = 1 THEN 'balkon o výměře ' || string_agg (bm.vymera_z_pv::TEXT, '') || ' m²'
		WHEN count(mistnost_id) = 2 THEN 'dva balkony o výměrách ' || string_agg (bm.vymera_z_pv::TEXT || ' m²', ' a ')  
		WHEN count(mistnost_id) = 3 THEN 'tři balkony o výměrách ' || string_agg (bm.vymera_z_pv::TEXT || ' m²', ' , ') 
		END as vymera 
	from byt_mistnost bm 
	where bm.mistnost_id in (22,23,24)
	group by byt_id
	) balkon ON balkon.byt_id = b.byt_id
LEFT JOIN (
	select byt_id, 
		CASE WHEN count(mistnost_id) = 1 THEN 'zatravněnou terasu o výměře ' || string_agg (bm.vymera_z_pv::TEXT, '') || ' m²'
		WHEN count(mistnost_id) = 2 THEN 'dvě zatravněné terasy o výměrách ' || string_agg (bm.vymera_z_pv::TEXT || ' m²', ' a ') 
		WHEN count(mistnost_id) = 3 THEN 'tři zatravněné terasy o výměrách ' || string_agg (bm.vymera_z_pv::TEXT || ' m²', ' , ') 
		END as vymera 
	from byt_mistnost bm 
	where bm.mistnost_id in (73,74,75)
	group by byt_id
	) zatravnena_terasa ON zatravnena_terasa.byt_id = b.byt_id
LEFT JOIN (
	select byt_id, 
		CASE WHEN count(mistnost_id) = 1 THEN 'terasu o výměře ' || string_agg (bm.vymera_z_pv::TEXT, '') || ' m²'
		WHEN count(mistnost_id) = 2 THEN 'dvě terasy o výměrách ' || string_agg (bm.vymera_z_pv::TEXT || ' m²', ' a ') 
		WHEN count(mistnost_id) = 3 THEN 'tři terasy o výměrách ' || string_agg (bm.vymera_z_pv::TEXT || ' m²', ' , ') 
		END as vymera 
	from byt_mistnost bm 
	where bm.mistnost_id in (19,20,21)
	group by byt_id
	) terasa on terasa.byt_id = b.byt_id
LEFT JOIN (
	select byt_id, 
		CASE WHEN count(mistnost_id) = 1 THEN 'lodžii o výměře ' || string_agg (bm.vymera_z_pv::TEXT, '') || ' m²'
		WHEN count(mistnost_id) = 2 THEN 'dvě lodžie o výměrách ' || string_agg (bm.vymera_z_pv::TEXT || ' m²', ' a ')
		WHEN count(mistnost_id) = 3 THEN 'tři lodžie o výměrách ' || string_agg (bm.vymera_z_pv::TEXT || ' m²', ' , ') 
		END as vymera 
	from byt_mistnost bm 
	where bm.mistnost_id in (99,98,93,92,27,26,25)
	group by byt_id
	) lodzie on lodzie.byt_id = b.byt_id
LEFT JOIN (
select 
		bm.byt_id, 
		pocet_predzahradek.pocet_predzahradek,
		CASE WHEN pocet_predzahradek = 1 THEN 'část' ELSE 'části' END AS predzahradka_cast,
		CASE WHEN pocet_predzahradek = 1 THEN 'předzahrádku - přístupnou' ELSE 'předzahrádky - přístupné' END AS predzahradka_pristupna,
		CASE WHEN pocet_predzahradek = 1 THEN 'předzahrádky' ELSE 'předzahrádek' END AS predzahradka_priloha,
		sum(vymera_z_pv)::text AS vymera,
		bm.katastr_predzahradka,
		bm.parcelni_cislo
	from byt_mistnost bm 
	LEFT JOIN (SELECT byt_id, count(mistnost_id) AS pocet_predzahradek FROM byt_mistnost  WHERE mistnost_id in (28,29,30)GROUP BY byt_id) pocet_predzahradek ON pocet_predzahradek.byt_id = bm.byt_id
	where bm.mistnost_id in (28,29,30, 70, 71, 72) 
	GROUP BY bm.byt_id, pocet_predzahradek, katastr_predzahradka,parcelni_cislo ) predzahradka ON predzahradka.byt_id = b.byt_id 
LEFT JOIN (
	SELECT 
		bm.byt_id, 
		'(z toho zpevněná plocha o výměře ' ||sum(vymera_z_pv) || ' m²)'AS vymera
	FROM byt_mistnost bm 
	LEFT JOIN (SELECT byt_id, count(mistnost_id) AS pocet_predzahradek FROM byt_mistnost GROUP BY byt_id) pocet_predzahradek ON pocet_predzahradek.byt_id = bm.byt_id
	where bm.mistnost_id in (70, 71, 72) 
	group by bm.byt_id
	) zpevnena_plocha ON zpevnena_plocha.byt_id = b.byt_id
LEFT JOIN (
	SELECT byt_id, string_agg(a.sklep, ' a ') AS sklep
	FROM (
	SELECT 	
			byt_id,
			upozorneni,
			CASE WHEN sklep_id IS NOT NULL THEN cislo_sklep || ' o výměře ' || round(sklep_vymera::NUMERIC, 1) || ' m²' END AS sklep
		FROM
			(SELECT 
				byt_id,
				s.sklep_id AS sklep_id,
				upozorneni,
				'S'|| ' ' || cvs.cislo_sklepa AS cislo_sklep,
				coalesce(vymera_z_pv, plocha) AS sklep_vymera	
			FROM sklep s
			LEFT JOIN byt_sklep bs ON bs.sklep_id = s.sklep_id AND bs.casova_hladina_id = (SELECT casova_hladina_id FROM casova_hladina ch WHERE ch.typ_casove_hladiny_id = 1) 
			LEFT JOIN (SELECT sklep_id, jednotka, plocha, vymera_z_pv, cislo_sklepa FROM casova_verze_sklep cvs WHERE cvs.casova_hladina_id = (SELECT casova_hladina_id FROM casova_hladina ch WHERE ch.typ_casove_hladiny_id = 1)) cvs ON cvs.sklep_id = s.sklep_id 
			) a
	)a
	GROUP BY byt_id
	) sklep ON sklep.byt_id = b.byt_id
LEFT JOIN (
	SELECT string_agg(x.ps, ' a ') AS ps, byt_id
	FROM (
	SELECT 
		bps.byt_id,
		ps.parkovaci_stani_id,
		--jtp.zkratka || ' ' || cvp.cislo_ps AS ps_cislo,
		--CASE WHEN ps.parkovaci_stani_id IS NOT NULL THEN CASE WHEN nazev LIKE 'vnitřní parkovací stání' THEN 'parkovací stání' ELSE nazev end  || ' označené jako ' || jtp.zkratka || ' ' || cvp.cislo_ps /*SUBSTRING(jednotka FROM '.*-(.*)')*/ END AS ps,
		CASE 
			WHEN jtp.zkratka = '2P' THEN 'P'
			WHEN jtp.zkratka = '2G' THEN 'G'
			ELSE jtp.zkratka
		END || ' ' || cvp.cislo_ps AS ps_cislo,
		CASE WHEN ps.parkovaci_stani_id IS NOT NULL THEN 
			CASE WHEN nazev in('vnitřní parkovací stání', 'kryté parkovací stání', 'rozšířené parkovací stání', 'dvojité parkovací stání') THEN 'parkovací stání' 
			WHEN nazev IN ('dvougarážové parkovací stání') THEN 'uzavřené parkovací stání'
			ELSE nazev end  || ' označené jako ' || CASE 
			WHEN jtp.zkratka = '2P' THEN 'P'
			WHEN jtp.zkratka = '2G' THEN 'G'
			ELSE jtp.zkratka
		END || ' ' || cvp.cislo_ps  /*SUBSTRING(jednotka FROM '.*-(.*)')*/ END AS ps,
		upozorneni,
		SUBSTRING(jednotka FROM '.*-(.*)') AS cislo_ps
	FROM parkovaci_stani ps 
	LEFT JOIN byt_parkovaci_stani bps ON bps.parkovaci_stani_id = ps.parkovaci_stani_id AND bps.casova_hladina_id = (SELECT casova_hladina_id FROM casova_hladina ch WHERE ch.typ_casove_hladiny_id = 1) 
	LEFT JOIN (SELECT parkovaci_stani_id, jednotka, cislo_ps FROM casova_verze_ps cvp WHERE cvp.casova_hladina_id = (SELECT casova_hladina_id FROM casova_hladina ch WHERE ch.typ_casove_hladiny_id = 1)) cvp ON cvp.parkovaci_stani_id = ps.parkovaci_stani_id 
	LEFT JOIN jv_typ_ps jtp ON jtp.typ_ps_id = ps.typ_ps_id  WHERE jtp.jazykova_verze_id = 1 AND jtp.casova_hladina_id = (SELECT casova_hladina_id FROM casova_hladina ch WHERE ch.typ_casove_hladiny_id = 1)
	) x
	GROUP BY byt_id
	) ps ON ps.byt_id = b.byt_id
LEFT JOIN (
	SELECT 
		bps.byt_id,
		jtp.zkratka AS zkratka
	FROM parkovaci_stani ps 
	LEFT JOIN byt_parkovaci_stani bps ON bps.parkovaci_stani_id = ps.parkovaci_stani_id AND bps.casova_hladina_id = (SELECT casova_hladina_id FROM casova_hladina ch WHERE ch.typ_casove_hladiny_id = 1) 
	LEFT JOIN (SELECT parkovaci_stani_id, jednotka, cislo_ps FROM casova_verze_ps cvp WHERE cvp.casova_hladina_id = (SELECT casova_hladina_id FROM casova_hladina ch WHERE ch.typ_casove_hladiny_id = 1)) cvp ON cvp.parkovaci_stani_id = ps.parkovaci_stani_id 
	LEFT JOIN jv_typ_ps jtp ON jtp.typ_ps_id = ps.typ_ps_id  WHERE jtp.jazykova_verze_id = 1 AND jtp.casova_hladina_id = (SELECT casova_hladina_id FROM casova_hladina ch WHERE ch.typ_casove_hladiny_id = 1)
	) ps_zkratka ON	ps_zkratka.byt_id = b.byt_id 
LEFT JOIN financovani f ON f.financovani_id = pns.financovani_id
LEFT JOIN cg_klient_hlavicka_html hlavicka ON hlavicka.klient_id = o.klient_id 
LEFT JOIN (
	SELECT bytovy_dum_id, 
		CASE WHEN bytovy_dum_id = 2311 THEN '<li>pozemek p.č. 2882/5 o výměře 1.015 m<sup>2</sup> (vč. Bytového domu, který je jeho součástí)</li><li>pozemek p.č. 2882/6 o výměře 20 m<sup>2</sup> (na němž Bytový dům rovněž stojí)</li><li>pozemek p.č. 2882/1 o výměře 967 m<sup>2</sup></li><li>pozemek p.č. 2882/10 o výměře 535 m<sup>2</sup></li><li>pozemek p.č. 2882/11 o výměře 522 m<sup>2</sup></li><li>pozemek p.č. 2882/12 o výměře 77 m<sup>2</sup></li><li>pozemek p.č. 2882/7 o výměře 28 m<sup>2</sup></li>'
	ELSE string_agg(pozemek.pozemek, '') END AS parcelni_cisla_pozemky
	FROM (
		SELECT p.bytovy_dum_id,
			'<li>pozemek p.č. '|| parcelni_cislo || ' o výměře ' || REPLACE(TO_CHAR(p.vymera, 'FM999,999,999'), ',', '.') || ' m<sup>2</sup>'|| CASE WHEN bd_je_soucasti = 1 THEN ' (vč. Bytového domu, který je jeho součástí)' ELSE '' END || '</li>' AS pozemek
		FROM pozemek p 
		WHERE  p.po_zamereni = 1
		ORDER BY bd_je_soucasti DESC, parcelni_cislo) pozemek
	GROUP BY bytovy_dum_id
) pozemky ON pozemky.bytovy_dum_id = bd.bytovy_dum_id
WHERE op.aktivni = 1 AND pns.typ_smlouvy_id = 44 AND pns.stav_zadosti_id NOT IN(8, 9, 10)


