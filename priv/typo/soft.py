#! /usr/bin/env python3
# -*- coding: UTF-8 -*-
#
"""Типограф Мягкий, сохраняет теховские фишки

Требования:
  - Python версии 3.0 и выше.
  - Обрабатываемый файл должен быть в кодировке UTF-8.

Использование:
  - $ python -O typo.py <текстовый файл>
  - $ echo 'bla-bla-bla' | python -O typo.py

Сайт проекта: <https://code.google.com/p/typo-tex-html/>
              <https://plus.google.com/104035776266274568778/>"""
__version__ = 1, 12, 0
__author__ = ["Александр <mono9lith@gmail.com>",]
__license__ = """\
Эта программа является свободным программным обеспечением: вы можете
использовать её согласно условиям открытого лицензионного соглашения GNU
(GNU GPL) версии 3 или, по вашему желанию, любой более поздней версии.

Эта программа распространяется в надежде, что она будет полезной, но без
каких-либо гарантий. Для получения более подробной информации смотрите
открытое лицензионное соглашение GNU: <http://www.gnu.org/licenses/>."""
#
import re

__all__ = ["typographize", "number"]

LEN = len
RANGE = range
DEBUG = False
# специальные символы re: \.^$?+*{}()[]|
# специальные символы latex: \$%_{}&#^~

#
#  Примечания
#
# - последовательность правил имеет значение
# - не писать конкретные буквы в замене из-за регистра
#TODO подумать как реализовать .format не нарушая регулярок
#TODO если появятся алфавитные свойства Unicode (\p{код}), изменить инициалы
#     и градусы
#TODO проверить правила на попадание на начало или конец документа
#TODO реализовать разбивку на абзацы в HTML
#TODO подумать как лучше - с NBSP или THINSP (чёрточки, циферки)
#TODO проверить конструкции с THINSP на необходимость неразрывности
#

# кавычки
LAQUO = "\u00ab"    # кавычка-ёлочка открывающая (")
RAQUO = "\u00bb"    # кавычка-ёлочка закрывающая (")
BDQUO = "\u201e"    # кавычка-лапка открывающая (')
LDQUO = "\u201c"    # кавычка-лапка закрывающая (')
LSQUO = "\u2018"    # кавычка одинарная открывающая (')
RSQUO = "\u2019"    # кавычка одинарная закрывающая (')
QUO_DBL = "\""

# пробелы
NBSP_U = "\u00a0"    # пробел неразрывный, растяжимый (в саду)
NBSP_T = "~"    # пробел неразрывный, растяжимый (в саду)

NBSP = NBSP_T    # пробел неразрывный, растяжимый (в саду)

THINSP = "\u2009"    # пробел тонкий, разрывный, нерастяжимый (10 000 000)

# чёрточки
HYP = "\u2010"    # дефис
NBHYP = HYP #"\u2011"    # дефис неразрывный (аб-вг)
NDASH = "\u2013"    # тире короткое (аб - вг)
MDASH = "\u2014"    # тире длинное (аб - вг)
SHY = "\u00ad"    # мягкий перенос

# математические
MINUS = "\u2212"    # минус (-123)
PLUSMN = "\u00b1"    # плюс-минус (+- или -+)
TIMES = "\u00d7"    # умножение-крест (12 XxХх34)
ASYMP = "\u2248"    # приближённо равно (~= или ~123)
NE = "\u2260"    # не равно (!=)
LE = "\u2264"    # меньше либо равно (<=)
GE = "\u2265"    # больше либо равно (>=)

# штрихи
APOS = RSQUO    # апостроф (абв'`где)
#ACUTE = "\u0301"    # знак ударения
PRIME = "\u2032"    # штрих одинарный
PRIME_DBL = "\u2033"    # штрих двойной

# остальные
HELLIP = "\u2026"    # многоточие (...)
COPY = "\u00a9"    # знак авторских прав (CcСс)
REG = "\u00ae"    # товарный знак (Rr)
TRADE = "\u2122"    # товарный знак (Tm)
LARR = "\u2190"    # стрелка влево (<-)
RARR = "\u2192"    # стрелка вправо (->)
SECT = "\u00a7"    # параграф
DEG = "\u00b0"    # знак градуса
SMILE = "\u263a"    # улыбка :)
#PHONE = "\u260e"    # изображение телефона
BULLET = "\u2022"

# наборы
DASHES = "-\u2010\u2011\u2012\u2013\u2014\u2015"    # без минуса
QUOTES = "'\"\u00ab\u2018\u201c\u201e\u2039\u00bb\u2019\u201d\u203a<>"
QUO_OPEN = "\u00ab\u2018\u201c\u201e\u2039"    # исключены неоднозначные ' и "
QUO_CLOSE = "\u00bb\u2019\u201c\u201d\u203a"
QUO_OPEN2 = "'\"\u00ab\u2018\u201c\u201e\u2039"    # с ' и "
QUO_CLOSE2 = "'\"\u00bb\u2019\u201c\u201d\u203a"
QUO_OPEN3 = "\u2018\u201c\u2039"    # без ' и ", AQUO
QUO_CLOSE3 = "\u2019\u201d\u203a"
BR_OPEN = r"\(\[\{<"
BR_CLOSE = r"\)\]\}>"
PUNCT = ".,!?:;" + HELLIP
PUNCT2 = ",!?:;"

# неопределённые местоимения
QUEST = (
        "куда|когда|зачем|почему|где|"
        "[кч]то|кого|чего|кому|чему|к[ео]м|ч[её]м|"
        "скольк(?:о|ими?|их)|"
        "как(?:ой|ов|ая|ую|ие|их|ое|ом|ого|ому)?|"
        "чей|чь[яюеё]|чьими?|чьих"
)

# предлоги и союзы (+ ещё кое-что)
PRE = (
    "а|в|во|вне|и|&|или|к|о|с|у|со|об|обо|от|ото|на|не|ни|но|из|изо|за|уж|по|"
    "под|подо|пред|предо|про|над|как|без|безо|что|да|для|ну|нет|до|там|"
    "ещ[её]|или|ко|меж|между|перед|передо|около|через|сквозь|при|близ|"
    "вместо|из[-{s0}]за|из[-{s0}]под|кроме|ради|среди|чрез|кое|кой|"
    "по[-{s0}]над|по[-{s0}]за|я|ты|вы|мы|он|она|они|оно|"
    "a|an|and|for|from|in|the|of|or|on".format(s0=NBHYP + HYP)
)

SHORT = "г|пос|ул|тов|д|с|гл|стр|рис|тел"    # сокращения
RULES = (
#
#   1. Нормализация
#   2. Скобки
#   3. Разное
#   4. Слова
#   5. Чёрточки
#   6. Кавычки
#   7. Знаки
#   8. Корректировка
#

#  0. Знаки
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# здесь простые правила, которые не работают после последующей обработки текста


## копирайт
#(r"\( ?[cс] ?\)", COPY),

## товарный знак
#(r" ?(?:{s0}|\( ?r ?\)|\( ?tm ?\))".format(s0=TRADE), REG),

## плюс-минус
#(r"(?:\+-|-\+) ?(?=\d)", PLUSMN),

## приближённо равно
#(r" ?~= ?", NBSP + ASYMP + " "),

## не равно
#(r" ?!= ?", NBSP + NE + " "),

## меньше либо равно
#(r" ?<= ?", NBSP + LE + " "),

## больше либо равно
#(r" ?>= ?", NBSP + GE + " "),

## смайл
#(r" ?(?:[:;]-?[\)\]]+|[\)\]]{2,})", " " + SMILE),

## стрелка влево
#(r"(?<![<>]) ?<--? ?(?!-)", NBSP + LARR + " "),

## стрелка вправо
#(r"(?<!-) ?-?-> ?(?![<>])", NBSP + RARR + " "),


## маркер
#(r" ?(?<!\*)\*(?!\*) ?", " " + BULLET + " "),

# двойное тире (после стрелок)
(r"-{3,}", MDASH),

# двойное тире (после стрелок)
(r"-{2,}", NDASH),

# теховский пробел
(r"%s" % NBSP_T, NBSP_U),


#  1. Нормализация
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#TODO удаление BOM?

## удаляет лишние пробелы и табы в начале и конце строки, переносы строки
#(r"(?:(?<=\n)|^)[ \t]+|[ \t]+(?:(?=\n)|$)|(?<=\n\n)\n+", r""),

# удаляет лишние пробелы и табы в тексте (\s съест перенос строки)
(r"[\t]{2,}", r" "),

# удаляет повторяющиеся слова (разрыв строки игнорируем -- неоднозначно)
(r"\b(\w+)[ \t]\1\b", r"\g<1>"),

# притягивает знаки препинания к предыдущему слову (перед кавычками)
# цифры исключаются, так как неоднозначно
(r"(?<=[\w{s0}])(?<!\d) ?([{s1}]+) ?(?!\d)(?:(?=[\n\w{s2}])|$)".format(
    s0=QUO_CLOSE, s1=PUNCT, s2=QUO_OPEN), r"\g<1> "),

# удаляет лишние знаки препинания (перед кавычками)
# точка исключается, чтобы 2 точки превратились в многоточие (см. Знаки)
(r"(?<![{s0}])([{s1}])\1(?:(?![{s0}])|$)".format(s0=PUNCT, s1=PUNCT2),
    r"\g<1>"),

# удаляет лишние эмоции
(r"([!?])\1{3,}", r"\g<1>\g<1>\g<1>"),

# меняет !? на ?!
#TODO правило захватывает просто ?!
(r"(?<=[\w{s0}{s1}])(?:!+\?+|\?+!+)[!?]*(?=[ \n]|$)".format(s0=QUO_CLOSE,
s1=BR_CLOSE), r"?!"),

# удаляет пробел перед или после дефиса
# проверить "англо-, франко- и русскоязычные"
# неоднозначно
#(r"(?<=\w)(?<!\d)( )?([%s])(?(1)| )(?!\d)(?=\w)" % DASHES, r"\g<2>"),
#(r"(?<=\w)(?<!\d) (?!\d)(?=[%s]\w)|(?<=\w[%s])(?<!\d) (?!\d)(?=\w)" %
#    (DASHES, DASHES), r""),

# удаляет лишние разрывы строки (после нормализации знаков препинания)
(r"(\w[,;]?) ?\n ?(?=\w)", r"\g<1> "),

# выделяет абзацы пустой строкой (после нормализации знаков препинания)
(r"(?<=\w[.!?{0}]) ?\n ?(?=[\w{1}])".format(HELLIP, QUO_OPEN), r"\n\n"),

# заменяет двойной символ № одинарным
(r"(?<!№)№№(?!№)", r"№"),

# вставляет пробелы вокруг &
(r"(?<=\w) ?& ?(?=\w)", r" &" + NBSP),


#  2. Скобки
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## вставляет пробел перед открывающей скобкой и после закрывающей (создаёт ^_)
#(r"(?<![ \n])(?=[{s0}])|(?<=[{s1}])(?![ {s2}])".format(s0=BR_OPEN, s1=BR_CLOSE,
    #s2=PUNCT), r" "),

## удаляет пробел после открывающей скобки и перед закрывающей
#(r"(?<=[{s0}]) | (?=[{s1}])".format(s0=BR_OPEN, s1=BR_CLOSE), r""),


#  3. Разное
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# нормализует пробел перед % (перед "обработкой пробелов после чисел")
(r"(?<=\d) ?(?=%)", THINSP),

# нормализует пробел после №, параграфа (перед заменой символов)
(r"(?<=[#№{s0}])(?: ?\n|\n? |)(?=\d)".format(s0=SECT), THINSP),

# нормализует пробелы вокруг доллара
(r"(?<!\d)(?<=\$)(?: ?\n|\n? |)(?=\d)|(?<=\d)(?: ?\n|\n? |)(?=\$)(?!\d)",
    NBSP),

# делает неразрывным пробел между разрядами чисел
# реализовано отдельно
#(r"(?<=\d)[ \n]?(?=(?:\d\d\d)+[^\d])", THINSP),
#  неоднозначно "...заказать 20 5-ти сантимертровых..."
#(r"(?<=\d)[ \n](?=\d)", THINSP),

# вставляет пробел перед числом (после нормализации знаков пр.)
# ложные срабатывания (VP9)
#(r"(?<=\w)(?<!\d)(?=\d)", r" "),

# делает неразрывным пробел после числа (после нормализации знаков пр.)
# перед чёрточками
#TODO цена $200 будет...
#TODO ки Ту-160*и Ту-22 М
#(r"(?:^|(?<= |[^\w]))(\d{1,5})[ \n]?(?!\d)(?=\w)", r"\g<1>" + THINSP),

# меняет пробел между числами на тонкий
(r"(?<=\d) (?=\d)", THINSP),

# заменяет точку между чисел на запятую (после нормализации знаков пр.)
# неоднозначно
#(r"\b(?<![,.])(\d+)\.(\d+)(?![,.])\b", r"\g<1>,\g<2>"),

# делает неразрывными инициалы и сокращения
(r"(?<=\b\w)(?<!\d)\. ?(?!\d)(?=\w\.)", r"." + NBSP),

# вставляет запятую перед а и но (учитывать неразрывный пробел)
(r"(?<=\w)[ {s0}](?=(?:а|но)[ {s0}]\w)".format(s0=NBSP + THINSP), r", "),

# конвертирует выделение
#TODO перенести в HTML emph
#(r"_(\w+)_", r"\\emph{\g<1>}"),

# выделяет заголовки (много ложных срабатываний)
#(r"(?<=\n\n)\n?(.{1,70}\w)(?=\n\n)", r"\\section{\g<1>}"),


#  4. Слова
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# после всех нормализаций
#TODO на~дачу и~в путешествия
#TODO Вышел FreeType 2.4.12*с реализацией

## вставляет дефис перед таки (после нормализации знаков препинания)
#(r"\b(вс[её]|так|опять|довольно)[-{s0} ]?(?=таки\b)".format(s0=HYP),
    #"\g<1>{s0}".format(s0=NBHYP)),

## вставляет дефис в местоимениях (после нормализации знаков препинания)
#(r"({s0})[-{s1} ]?(?=либо\b|нибудь\b|то\b[^:])".format(s0=QUEST, s1=HYP),
    #"\g<1>{s0}".format(s0=NBHYP)),

## вставляет дефис перед (после нормализации знаков препинания)
#(r"(?<=\w)(?<!\d)[-{s0} ](?=(?:ка|де|кась)\b)".format(s0=HYP), NBHYP),

## вставляет дефис в местоимениях (после нормализации знаков препинания)
#(r"(?<=\bко[ей])[-{s0} ]?(?={s1})".format(s0=HYP, s1=QUEST), NBHYP),

## вставляет дефис в словах из-за и из-под (корректировка перед предлогами!)
#(r"(?<=\bиз)[-{s0} ]?(?=(?:за|под)\b)|(?<=\bпо)[-{s0} ](?=(?:за|над)\b)".format(s0=HYP),
    #NBHYP),

# вставляет неразрывный пробел после предлогов и союзов
# (после нормализации знаков препинания)
# если использовать просто \b, то захватится "что-то случилось"
# если не захватывать символ перед предлогом, может получается ситуация
# предлог~предлог~слово
#
(r"([^-{s0}]\b|^)({s1}) (?=[\w{s2}])".format(s0=NBSP + NBHYP + THINSP, s1=PRE, s2=QUO_OPEN2),
    r"\g<1>\g<2>" + NBSP),

# вставляет неразрывный пробел перед частицами
(r"(?<=\w)(?<!\d) (?=(?:ж|бы|б|же|ли|ль)\b)", NBSP),

# вставляет неразрывный пробел после сокращений
(r"(\b(?:{s0})\.) ?(?=\w)".format(s0=SHORT), r"\g<1>" + NBSP),


#  5. Чёрточки
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#TODO диапозоны и телефонные номера должны быть с разными чёрточками
#TODO реализовать в HTML <nobr>word*-</nobr>*word
#TODO <тире-и-без-пробела...>слово -> <тире-с-пробелом...> слово

# нормализует ситуацию "слово,-слово" перед норм. тире
# реализовано ниже
#(r"(?<=\w,)(?=[{s0}])".format(s0=DASHES), r" "),

# нормализует тире
(r"(?: |(?<=[.,]))(["+ DASHES + "])\1{0,2}(?: ?|(?=\n))", NBSP + MDASH +
    " "),

# нормализует прямую речь
# небольшой конфликт с правилом минуса
(r"(?:(?<=\n)|^) ?([" + DASHES + "])\1{0,2} ?(?=\w)", MDASH + NBSP),

# настраивает диапозоны (принять во внимание пересечение: "(1-[2)-3]")
# переходы на новую строку съедаются
(r"(?<=\d)\n?([{s0}])\1?\n?(?=\d)".format(s0=DASHES), MDASH),

# делает неразрывными "телефонные номера" (после диапозонов)
# указывать диапозон чёрточек первым в символьном классе
#TODO перенести в HTML mbox
#(r"(?<![{s0}])\b(\d+[{s0}]+\d+[{s0}\d]*\d)(?![{s0}])".format(s0=DASHES),
#    r"\\mbox{\g<1>}"),

# делает неразрывным дефис в словах с короткой частью
# не нужно из-за полной замены - на NBHYP везде
#(r"(\b\w{1,2})(?<!\d)\n?[" + DASHES + "]\n?(?!\d)(?=\w{1,2})", r"\g<1>" +
#    NBHYP),

# делает неразрывным дефис в словах с короткой 1-й частью
# не нужно из-за полной замены - на NBHYP везде
#(r"(\d|\b\w{1,2})\n?[" + DASHES + "]\n?(?!\d)(?=\w)", r"\g<1>" + NBHYP),

# делает неразрывным дефис в словах с короткой 2-й частью
# не нужно из-за полной замены - на NBHYP везде
#(r"(?<=\w)(?<!\d)\n?[" + DASHES + "]\n?(?=\w{1,2}\b)", NBHYP),

# заменяет дефисоминус минусом перед числом
(r"(?<![+{s0}])(?<!\w)[{s0}](?=\d)".format(s0=DASHES), MINUS),


#  6. Кавычки
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#TODO "И цвет мой самый любимый - "эсмеральда"".

# заменяет на кавычку ёлочку открывающую
(r"(?:(?<=[ \t\n{s1}{s2}{s3}])|^)[{s0}](?=[{s2}]?\w)".format(s0=QUO_DBL,
    s1=BR_OPEN, s2=QUO_OPEN2, s3=NBSP), LAQUO),

# заменяет на кавычку ёлочку закрывающую
(r"(\w[{s1}{s3}]?)[{s0}](?:(?=[ \t\n{s1}{s2}{s3}{s4}])|$)".format(s0=QUO_DBL,
    s1=PUNCT, s2=BR_CLOSE, s3=QUO_CLOSE2, s4=NBSP), r"\g<1>" + RAQUO),

## заменяет на кавычку лапку открывающую
#(r"(?:(?<=[ \t\n{s1}{s2}{s3}])|^)[{s0}](?=[{s2}]?\w)".format(s0="'" + QUO_OPEN3,
    #s1=BR_OPEN, s2=QUO_OPEN2, s3=NBSP), BDQUO),

## заменяет на кавычку лапку закрывающую
#(r"(\w[{s1}{s3}]?)[{s0}](?:(?=[ \t\n{s1}{s2}{s3}{s4}])|$)".format(s0="'" +
    #QUO_CLOSE3, s1=PUNCT, s2=BR_CLOSE, s3=QUO_CLOSE2, s4=NBSP), r"\g<1>" + LDQUO),

# заменяет на кавычку лапку открывающую
#(r"(?:(?<=[ \t\n{s1}])|^)[{s0}](?=\w)".format(s0="'\u2018\u2039" + LDQUO,
#    s1=PUNCT), BDQUO),

# заменяет на кавычку лапку закрывающую
#(r"(\w[{s1}]?)[{s0}](?:(?=[ \t\n{s1}])|$)".format(s0="'\u2019\u203a\u201d",
#    s1=PUNCT), r"\g<1>" + LDQUO),

# заменяет кавычку двойную открывающую (лапку закрывающую) в начале слова
# на кавычку лапку открывающую
# реализовано выше
#(r"(?<=[ \t]){s0}(?=\w)".format(s0=LDQUO), BDQUO),

# вставляет тонкий пробел между кавычками
(r"(?<=[{s0}])(?=[{s0}])|(?<=[{s1}])(?=[{s1}])".format(s0=LAQUO + BDQUO,
    s1=RAQUO + LDQUO), THINSP),

# убирает точку изнутри конструкции в кавычках
# будет ложное срабатывание, если внутри кавычек сокращение
(r"(?<=\w)\.(?=[{s0}]\.[^\w])".format(s0=QUO_CLOSE), r""),

# убирает знак препинания снаружи конструкции в кавычках
(r"(?<=\w([?!{s0}])[{s1}])\1(?=[^\w])".format(s0=HELLIP, s1=QUO_CLOSE), r""),

#TODO надо ли
# вставляет пробел перед открывающей кавычкой и после закрывающей (создаёт ^_)
#(r"(?<![ \n{s3}])(?=[{s0}])|(?<=[{s1}])(?![ {s2}{s3}])".format(s0=QUO_OPEN, s1=QUO_CLOSE,
#    s2=PUNCT, s3=NBSP), r" "),

#TODO надо ли
# удаляет пробел после открывающей кавычки и перед закрывающей
#(r"(?<=[{s0}]) | (?=[{s1}])".format(s0=QUO_OPEN, s1=QUO_CLOSE), r""),


#  7. Знаки
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#TODO перенести в 0 уровень

# заменяет короткое тире длинным
(NDASH, MDASH),

# заменяет дефис неразрывным
#(r"(?<=\w)(?<!\d)[-{s0}](?!\d)(?=\w)".format(s0=HYP), NBHYP),

# пуля
#(r"%s" % "\u2022", r"\\textbullet{}"),

# товарный знак 2
#(r"\(tm\)", r"\\texttrademark{}"),

# номер
#(r"%s" % "\u2116", r"\\No{}"),

# параграф
#(r"%s" % "\u00a7", r"\\S{}"),

# абзац
#(r"%s" % "\u00b6", r"\\P{}"),

# градус
#(r"%s" % "\u00b0", r"\\textdegree{}"),

# градус Цельсия
(r"(?<=\d)[ {s0}]?{s1}c".format(s0=NBSP+THINSP, s1=DEG), THINSP + DEG + "C"),

# градус Фаренгейта
(r"(?<=\d)[ {s0}]?{s1}f".format(s0=NBSP+THINSP, s1=DEG), THINSP + DEG + "F"),

# многоточие
(r"(?<!\.)\.{2,5}(?!\.)", HELLIP),

# двойной штрих (до апострофа)
(r"(?<!['`])(['`])\1(?!['`])", PRIME_DBL),

## апостроф
##TODO нужно ли только внутри слова?
#(r"['`]+", APOS),

# неразрывный пробел
#(r"%s" % "\u00a0", r"~"),

# мягкий перенос
#(r"(?<=\w)%s(?=\w)" % "\u00ad", r"\\-"),

# ударение (может быть и после последней буквы слова)
#(r"(\w)(?<!\d)%s" % "\u0301", r"\\'{\g<1>}"),

# микро
#(r"%s" % "\u00b5", r"\\textmu{}"),

# меняет x на правильный
(r"(?<=\d)[ {s0}]?[XxХх] ?(?=\d)".format(s0=NBSP + THINSP), THINSP + TIMES +
    THINSP),

# телефон
#(r"\bтел\. ?:[ {s0}]?(?=[\d{s1}])".format(s0=NBSP, s1=BR_OPEN), PHONE + NBSP),

# дроби
#(r"\b1/4\b", r"\\char%s00BC{}" % QUO_DBL),

# дроби
#(r"\b1/2\b", r"\\char%s00BD{}" % QUO_DBL),

# дроби
#(r"\b3/4\b", r"\\char%s00BE{}" % QUO_DBL),


#  8. Корректировка
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## удаляет лишние пробелы и табы в начале и конце строки, переносы строки
#(r"(?:(?<=\n)|^)[ \t]+|[ \t]+(?:(?=\n)|$)|(?<=\n\n)\n+", r""),

## добавляет перевод строки в конец документа
#(r"(?<!\n)$", r"\n"),

(".\ png", ".png"),

)
RULES_DBG = (

#  Выделение невидимых символов
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# пробел неразрывный
(r"%s" % NBSP_U, r"%s" % NBSP_T),

# пробел тонкий
(THINSP, r"\,"),

# дефис неразрывный
(NBHYP, r"-"),

)


def typographize(text):
    """Обрабатывает текст

    возвращает <str>: обработанный текст

    параметр <str> text: текст для обработки
    """
    if not text:
        return text
#    if DEBUG:
#        RULES += RULES_DBG
#        print("[debug] typo: len(RULES):", LEN(RULES))
    RE_C = re.compile
    RE_I = re.IGNORECASE
    for ruleFrom, ruleTo in RULES + RULES_DBG:
        r = RE_C(ruleFrom, RE_I)
        text = r.sub(ruleTo, text)

    # Вставляет разделители тысячных в числа
    r = RE_C(r"(?<![\d,.])\d+([.,]\d+)?(?![\d,.])", RE_I)
    return r.sub(number, text)


def number(match):
    """Вставляет разделители тысячных в числа"""
#
# Неоднозначные ситуации:
#
# 1. одна запятая, мало цифр: 1,234 (1,1345 или 1234,5 -- уже однозначны)
# 2. запятая и точка: 1,234.5
#
# Однозначные ситуации (распространённые):
#
# 1. дробной части нет:
#    1234567890 или 1 234 567 890 или 1,234,567,890 или 1'234'567'890
# 2. дробная часть точка:
#    12345.67890 или 12 345.678 90 или 12,345.678,90 или 12'345.678'90
# 3. Дробная часть запятая:
#    12345,67890 или 12 345,678 90 или 12.345,678.90
#
    NUM_FORMAT = "{0},{1}".format
    text = match.group(0)
    if LEN(text) < 5:
        return text
    a = text.count(".")
    b = text.count(",")
    left = ""
    right = ""

    # ситуация 1: дробной части нет, разделителей нет
    if a == 0 and b == 0:
        if text.isdigit():
            left = text
        else:
            return text

    # ситуация 2: дробная часть запятая или точка, разделителей нет
    elif (a == 0 and b == 1) or (a == 1 and b == 0):
        temp = text.split("," if a == 0 else ".")
        if temp[0].isdigit() and temp[1].isdigit():
            left = temp[0]
            right = temp[1]
        else:
            return text
    else:
        return text

    # проверка на длину
    if LEN(left) < 5 and LEN(right) < 5:
        return text

    if not right:
        return splitNum(left)
    else:
        return NUM_FORMAT(splitNum(left), splitNum(right, False))


def splitNum(text, invert=True):
    """Разбивает число на части (тысячные)"""
    THINSP = "\u2009"
    leng = LEN(text)
    if leng < 5:
        return text
    if invert:
        text = text[::-1]
    mass = [text[i * 3:(i * 3) + 3] for i in RANGE(leng // 3)]
    MASS_APPEND = mass.append
    if leng % 3 != 0:
        MASS_APPEND(text[leng - (leng % 3):])
    result = THINSP.join(mass)
    return result[::-1] if invert else result


def check(text):
    """Проверяет результат на качество"""
    if not text:
        return text
    ACUTE_WORDS = (
    "больш(?:ая|ую|ие|их|ими?)|"
    "понят(?:ой|ая|ые|ого|ую|ых|ыми?)|"
    "должно|"
    "знаком|"
    "самого|"
    "потом|"
    "признают|"
    "хлопок|"
    "сведени[ие]|"
    "видени[еяю]|"
    "временн(?:ой|ая|ую|ые|ых|ыми?|ого|ом)|"
    "мука"
    )
    RE_C = re.compile
    RE_I = re.IGNORECASE

    leng = LEN(text)

    NBSP = "\u00a0"
    result = []
    RESULT_APPEND = result.append

    # ищет ошибки со смесью кириллицы и латиницы в 1 слове
    RESULT_APPEND("Найдены ошибки со смесью кириллицы и латиницы в 1 слове:\n")
    r = RE_C(r"[A-Za-z][А-Яа-я]+|[А-Яа-я][A-Za-z]+", RE_I)
    for string in r.findall(text):
        RESULT_APPEND(string)

    # ищет ошибки с неразрывным пробелом
    RESULT_APPEND("Найдены ошибки с неразрывным пробелом:\n")
    r = RE_C(r"\b\w+{s0}\w+{s0}[{s0}\w]+".format(s0=NBSP), RE_I)
    for string in r.findall(text):
        RESULT_APPEND(string)

    # ищет слова с отсутствующим ударением
    RESULT_APPEND("Найдены слова с отсутствующим ударением:\n")
    r = RE_C(r"{s0}".format(s0=ACUTE_WORDS), RE_I)
    for string in r.findall(text):
        RESULT_APPEND(string)
    RESULT_APPEND("\n")
    return "\n".join(result)


def main():
    import sys
    import os
    stdio = not sys.stdin.isatty()
    if LEN(sys.argv) != 2 and not stdio:
        print("Для работы программы необходимо указать 1 аргумент.")
        if __doc__: print(__doc__)
        return 2
    if stdio:
        sys.stdout.write(typographize(sys.stdin.read()))
    else:
        theResult = None
        fileName = os.path.basename(sys.argv[1])
        RESULT = "Результат [{0}].txt".format(fileName)
        with open(sys.argv[1], encoding="UTF-8") as inFile,\
        open(RESULT, "w", encoding="UTF-8") as outFile:
            theResult = typographize(inFile.read())
            outFile.write(theResult)
            print("записано \"{0}\"".format(RESULT))
        LOG = "Отчёт [{0}].txt".format(fileName)
        with open(LOG, "w", encoding="UTF-8") as logFile:
            logFile.write(check(theResult))
            print("записано \"{0}\"".format(LOG))


if __name__ == "__main__":
    main()
