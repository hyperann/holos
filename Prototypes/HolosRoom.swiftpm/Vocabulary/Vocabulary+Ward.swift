import Foundation

/// The hospital ward.
///
/// Each object carries the sentences a person in that bed most often needs
/// about it. Labels stay short enough to read at a glance; what is spoken
/// is a whole, polite sentence, so the person never sounds more abrupt
/// than they are. Ukrainian requests use the polite plural to staff
/// ("Покличте", "Відчиніть"), as anyone would say them on a ward.
///
/// Frames are in room space (1000 × 700) and match the drawing in
/// `WardArt`. The order follows the eye left to right, by where each
/// object begins — which also puts the bed, and "I'm in pain", second.
extension Vocabulary {
    static let ward: [Hotspot] = [
        Hotspot(
            id: "ward.window",
            name: Bilingual("Window", uk: "Вікно"),
            frame: ArtRect(20, 44, 300, 284),
            labelAt: ArtPoint(170, 292),
            choices: [
                RoomChoice(Phrase(
                    "ward.window.hot",
                    Bilingual("I'm too hot", uk: "Мені жарко"),
                    says: Bilingual("I'm too hot.", uk: "Мені занадто жарко."),
                    symbol: "thermometer.sun.fill", kind: .describing
                )),
                RoomChoice(Phrase(
                    "ward.window.cold",
                    Bilingual("I'm too cold", uk: "Мені холодно"),
                    says: Bilingual("I'm too cold.", uk: "Мені занадто холодно."),
                    symbol: "thermometer.snowflake", kind: .describing
                )),
                RoomChoice(Phrase(
                    "ward.window.open",
                    Bilingual("Open the window", uk: "Відчиніть вікно"),
                    says: Bilingual("Open the window, please.", uk: "Відчиніть вікно, будь ласка."),
                    symbol: "wind", kind: .action
                )),
                RoomChoice(Phrase(
                    "ward.window.curtains",
                    Bilingual("Close the curtains", uk: "Засуньте штори"),
                    says: Bilingual("Close the curtains, please.", uk: "Засуньте штори, будь ласка."),
                    symbol: "moon.fill", kind: .action
                )),
            ]
        ),
        Hotspot(
            id: "ward.bed",
            name: Bilingual("Bed", uk: "Ліжко"),
            frame: ArtRect(140, 330, 450, 270),
            labelAt: ArtPoint(430, 360),
            choices: [
                // First in the ring: pain must be the fastest thing to say.
                RoomChoice(Phrase(
                    "ward.bed.pain",
                    Bilingual("I'm in pain", uk: "Мені боляче"),
                    says: Bilingual("I'm in pain.", uk: "Мені боляче."),
                    symbol: "bandage.fill", kind: .urgent
                )),
                RoomChoice(Phrase(
                    "ward.bed.sitUp",
                    Bilingual("Help me sit up", uk: "Допоможіть сісти"),
                    says: Bilingual("Please help me sit up.", uk: "Допоможіть мені сісти в ліжку, будь ласка."),
                    symbol: "chair.fill", kind: .action
                )),
                RoomChoice(Phrase(
                    "ward.bed.lieDown",
                    Bilingual("I want to lie down", uk: "Хочу лягти"),
                    says: Bilingual("I want to lie down.", uk: "Я хочу лягти."),
                    symbol: "bed.double.fill", kind: .action
                )),
                RoomChoice(Phrase(
                    "ward.bed.sleep",
                    Bilingual("I can't sleep", uk: "Не можу заснути"),
                    says: Bilingual("I can't sleep.", uk: "Я не можу заснути."),
                    symbol: "moon.zzz.fill", kind: .describing
                )),
            ]
        ),
        Hotspot(
            id: "ward.body",
            // A pain body chart, as speech therapists pin beside the bed:
            // pointing at where it hurts is easier than naming it.
            name: Bilingual("My body", uk: "Моє тіло"),
            frame: ArtRect(345, 66, 160, 212),
            labelAt: ArtPoint(425, 254),
            choices: [
                RoomChoice(Phrase(
                    "ward.body.head",
                    Bilingual("My head hurts", uk: "Болить голова"),
                    says: Bilingual("My head hurts.", uk: "У мене болить голова."),
                    symbol: "brain.head.profile", kind: .urgent
                )),
                RoomChoice(Phrase(
                    "ward.body.chest",
                    Bilingual("My chest hurts", uk: "Болить у грудях"),
                    says: Bilingual("My chest hurts.", uk: "У мене болить у грудях."),
                    symbol: "lungs.fill", kind: .urgent
                )),
                RoomChoice(Phrase(
                    "ward.body.stomach",
                    Bilingual("My stomach hurts", uk: "Болить живіт"),
                    says: Bilingual("My stomach hurts.", uk: "У мене болить живіт."),
                    symbol: "cross.case.fill", kind: .urgent
                )),
                RoomChoice(Phrase(
                    "ward.body.leg",
                    Bilingual("My leg hurts", uk: "Болить нога"),
                    says: Bilingual("My leg hurts.", uk: "У мене болить нога."),
                    symbol: "shoeprints.fill", kind: .urgent
                )),
            ]
        ),
        Hotspot(
            id: "ward.phone",
            name: Bilingual("Phone", uk: "Телефон"),
            frame: ArtRect(548, 132, 172, 142),
            labelAt: ArtPoint(634, 262),
            choices: [
                RoomChoice(Phrase(
                    "ward.phone.wife",
                    Bilingual("Call my wife", uk: "Подзвоніть дружині"),
                    says: Bilingual("Please call my wife.", uk: "Подзвоніть моїй дружині, будь ласка."),
                    symbol: "phone.fill", kind: .people
                )),
                RoomChoice(Phrase(
                    "ward.phone.mum",
                    Bilingual("Call my mum", uk: "Подзвоніть мамі"),
                    says: Bilingual("Please call my mum.", uk: "Подзвоніть моїй мамі, будь ласка."),
                    symbol: "phone.fill", kind: .people
                )),
                RoomChoice(Phrase(
                    "ward.phone.son",
                    Bilingual("Call my son", uk: "Подзвоніть синові"),
                    says: Bilingual("Please call my son.", uk: "Подзвоніть моєму синові, будь ласка."),
                    symbol: "phone.fill", kind: .people
                )),
                RoomChoice(Phrase(
                    "ward.phone.home",
                    Bilingual("I want to go home", uk: "Хочу додому"),
                    says: Bilingual("I want to go home.", uk: "Я хочу додому."),
                    symbol: "house.fill", kind: .action
                )),
            ]
        ),
        Hotspot(
            id: "ward.table",
            name: Bilingual("Bedside table", uk: "Тумбочка"),
            frame: ArtRect(598, 306, 192, 294),
            labelAt: ArtPoint(690, 566),
            choices: [
                RoomChoice(Phrase(
                    "ward.table.water",
                    Bilingual("Water", uk: "Вода"),
                    says: Bilingual("Water, please.", uk: "Води, будь ласка."),
                    symbol: "drop.fill", kind: .thing
                )),
                RoomChoice(Phrase(
                    "ward.table.medicine",
                    Bilingual("Medicine", uk: "Ліки"),
                    says: Bilingual("Medicine, please.", uk: "Ліки, будь ласка."),
                    symbol: "pills.fill", kind: .thing
                )),
                RoomChoice(Phrase(
                    "ward.table.hungry",
                    Bilingual("I'm hungry", uk: "Я голодний", ukFeminine: "Я голодна"),
                    says: Bilingual("I'm hungry.", uk: "Я голодний.", ukFeminine: "Я голодна."),
                    symbol: "fork.knife", kind: .describing
                )),
                RoomChoice(Phrase(
                    "ward.table.glasses",
                    Bilingual("My glasses", uk: "Мої окуляри"),
                    says: Bilingual("My glasses, please.", uk: "Дайте, будь ласка, мої окуляри."),
                    symbol: "eyeglasses", kind: .thing
                )),
            ]
        ),
        Hotspot(
            id: "ward.nurse",
            name: Bilingual("Nurse", uk: "Медсестра"),
            frame: ArtRect(800, 80, 186, 452),
            labelAt: ArtPoint(890, 510),
            choices: [
                RoomChoice(Phrase(
                    "ward.nurse.call",
                    Bilingual("Call the nurse", uk: "Покличте медсестру"),
                    says: Bilingual("Please call the nurse.", uk: "Покличте медсестру, будь ласка."),
                    symbol: "person.wave.2.fill", kind: .people
                )),
                RoomChoice(Phrase(
                    "ward.nurse.wait",
                    Bilingual("Please wait", uk: "Зачекайте"),
                    says: Bilingual("Please wait.", uk: "Зачекайте, будь ласка."),
                    symbol: "hourglass", kind: .social
                )),
                RoomChoice(Phrase(
                    "ward.nurse.slowly",
                    Bilingual("Speak slowly", uk: "Говоріть повільніше"),
                    says: Bilingual("Please speak slowly.", uk: "Говоріть повільніше, будь ласка."),
                    symbol: "tortoise.fill", kind: .social
                )),
                RoomChoice(Phrase(
                    "ward.nurse.thanks",
                    Bilingual("Thank you", uk: "Дякую"),
                    says: Bilingual("Thank you.", uk: "Дякую."),
                    symbol: "heart.circle.fill", kind: .social
                )),
            ]
        ),
    ]
}
