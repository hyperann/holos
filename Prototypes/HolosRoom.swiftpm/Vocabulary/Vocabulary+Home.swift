import Foundation

/// Home: the familiar room.
///
/// The family photo is different from every other object. It holds people,
/// not sentences: choose a face, and the sentences about that person bloom
/// next. For someone with word-finding aphasia that is the difference
/// between "call my… my…" and being understood — the face is recognised
/// even when the word for her is gone.
///
/// Frames are in room space (1000 × 700) and match the drawing in
/// `HomeArt`; the order is the order the eye reads the room.
extension Vocabulary {
    static let home: [Hotspot] = [
        Hotspot(
            id: "home.fridge",
            name: Bilingual("Fridge", uk: "Холодильник"),
            frame: ArtRect(20, 160, 170, 440),
            labelAt: ArtPoint(105, 196),
            choices: [
                RoomChoice(Phrase(
                    "home.fridge.hungry",
                    Bilingual("I'm hungry", uk: "Я голодний", ukFeminine: "Я голодна"),
                    says: Bilingual("I'm hungry.", uk: "Я голодний.", ukFeminine: "Я голодна."),
                    symbol: "fork.knife", kind: .describing
                )),
                RoomChoice(Phrase(
                    "home.fridge.sweet",
                    Bilingual("Something sweet", uk: "Щось солодке"),
                    says: Bilingual("Something sweet, please.", uk: "Чогось солодкого, будь ласка."),
                    symbol: "birthday.cake.fill", kind: .thing
                )),
                RoomChoice(Phrase(
                    "home.fridge.notNow",
                    Bilingual("Not now", uk: "Не зараз"),
                    says: Bilingual("Not now, thank you.", uk: "Не зараз, дякую."),
                    symbol: "hand.raised.fill", kind: .social
                )),
            ]
        ),
        Hotspot(
            id: "home.kettle",
            name: Bilingual("Kettle", uk: "Чайник"),
            frame: ArtRect(190, 318, 178, 280),
            labelAt: ArtPoint(278, 560),
            choices: [
                RoomChoice(Phrase(
                    "home.kettle.tea",
                    Bilingual("Tea", uk: "Чай"),
                    says: Bilingual("Tea, please.", uk: "Чаю, будь ласка."),
                    symbol: "cup.and.saucer.fill", kind: .thing
                )),
                RoomChoice(Phrase(
                    "home.kettle.coffee",
                    Bilingual("Coffee", uk: "Кава"),
                    says: Bilingual("Coffee, please.", uk: "Кави, будь ласка."),
                    symbol: "mug.fill", kind: .thing
                )),
                RoomChoice(Phrase(
                    "home.kettle.water",
                    Bilingual("Water", uk: "Вода"),
                    says: Bilingual("Water, please.", uk: "Води, будь ласка."),
                    symbol: "drop.fill", kind: .thing
                )),
            ]
        ),
        Hotspot(
            id: "home.photo",
            name: Bilingual("Family photo", uk: "Сімейне фото"),
            frame: ArtRect(402, 72, 206, 166),
            labelAt: ArtPoint(505, 226),
            choices: [
                RoomChoice(
                    Phrase("home.photo.wife", Bilingual("My wife", uk: "Моя дружина"), symbol: "person.fill", kind: .people),
                    more: [
                        Phrase(
                            "home.photo.wife.call",
                            Bilingual("Call my wife", uk: "Подзвоніть дружині"),
                            says: Bilingual("Please call my wife.", uk: "Подзвоніть моїй дружині, будь ласка."),
                            symbol: "phone.fill", kind: .people
                        ),
                        Phrase(
                            "home.photo.wife.miss",
                            Bilingual("I miss my wife", uk: "Сумую за дружиною"),
                            says: Bilingual("I miss my wife.", uk: "Я сумую за дружиною."),
                            symbol: "heart.fill", kind: .describing
                        ),
                    ]
                ),
                RoomChoice(
                    Phrase("home.photo.children", Bilingual("My children", uk: "Мої діти"), symbol: "figure.and.child.holdinghands", kind: .people),
                    more: [
                        Phrase(
                            "home.photo.children.call",
                            Bilingual("Call my children", uk: "Подзвоніть дітям"),
                            says: Bilingual("Please call my children.", uk: "Подзвоніть моїм дітям, будь ласка."),
                            symbol: "phone.fill", kind: .people
                        ),
                        Phrase(
                            "home.photo.children.miss",
                            Bilingual("I miss my children", uk: "Сумую за дітьми"),
                            says: Bilingual("I miss my children.", uk: "Я сумую за дітьми."),
                            symbol: "heart.fill", kind: .describing
                        ),
                    ]
                ),
                RoomChoice(
                    Phrase("home.photo.mum", Bilingual("My mum", uk: "Моя мама"), symbol: "person.crop.circle.fill", kind: .people),
                    more: [
                        Phrase(
                            "home.photo.mum.call",
                            Bilingual("Call my mum", uk: "Подзвоніть мамі"),
                            says: Bilingual("Please call my mum.", uk: "Подзвоніть моїй мамі, будь ласка."),
                            symbol: "phone.fill", kind: .people
                        ),
                        Phrase(
                            "home.photo.mum.miss",
                            Bilingual("I miss my mum", uk: "Сумую за мамою"),
                            says: Bilingual("I miss my mum.", uk: "Я сумую за мамою."),
                            symbol: "heart.fill", kind: .describing
                        ),
                    ]
                ),
            ]
        ),
        Hotspot(
            id: "home.sofa",
            name: Bilingual("Sofa", uk: "Диван"),
            frame: ArtRect(398, 360, 324, 240),
            labelAt: ArtPoint(612, 578),
            choices: [
                RoomChoice(Phrase(
                    "home.sofa.rest",
                    Bilingual("I want to rest", uk: "Хочу відпочити"),
                    says: Bilingual("I want to rest.", uk: "Я хочу відпочити."),
                    symbol: "zzz", kind: .action
                )),
                RoomChoice(Phrase(
                    "home.sofa.sit",
                    Bilingual("Help me sit down", uk: "Допоможіть сісти"),
                    says: Bilingual("Please help me sit down.", uk: "Допоможіть мені сісти, будь ласка."),
                    symbol: "chair.fill", kind: .action
                )),
                RoomChoice(Phrase(
                    "home.sofa.comfortable",
                    Bilingual("I'm comfortable", uk: "Мені зручно"),
                    says: Bilingual("I'm comfortable.", uk: "Мені зручно."),
                    symbol: "face.smiling", kind: .describing
                )),
            ]
        ),
        Hotspot(
            id: "home.tv",
            name: Bilingual("TV", uk: "Телевізор"),
            frame: ArtRect(606, 104, 220, 150),
            labelAt: ArtPoint(716, 242),
            choices: [
                RoomChoice(Phrase(
                    "home.tv.on",
                    Bilingual("Turn it on", uk: "Увімкніть"),
                    says: Bilingual("Please turn on the TV.", uk: "Увімкніть телевізор, будь ласка."),
                    symbol: "tv.fill", kind: .action
                )),
                RoomChoice(Phrase(
                    "home.tv.off",
                    Bilingual("Turn it off", uk: "Вимкніть"),
                    says: Bilingual("Please turn off the TV.", uk: "Вимкніть телевізор, будь ласка."),
                    symbol: "xmark.circle.fill", kind: .action
                )),
                RoomChoice(Phrase(
                    "home.tv.louder",
                    Bilingual("Louder", uk: "Гучніше"),
                    says: Bilingual("Louder, please.", uk: "Гучніше, будь ласка."),
                    symbol: "speaker.wave.2.fill", kind: .describing
                )),
                RoomChoice(Phrase(
                    "home.tv.quieter",
                    Bilingual("Quieter", uk: "Тихіше"),
                    says: Bilingual("Quieter, please.", uk: "Тихіше, будь ласка."),
                    symbol: "speaker.slash.fill", kind: .describing
                )),
            ]
        ),
        Hotspot(
            id: "home.door",
            name: Bilingual("Door", uk: "Двері"),
            frame: ArtRect(836, 98, 158, 434),
            labelAt: ArtPoint(915, 508),
            choices: [
                RoomChoice(Phrase(
                    "home.door.outside",
                    Bilingual("I want to go outside", uk: "Хочу на вулицю"),
                    says: Bilingual("I want to go outside.", uk: "Я хочу вийти на вулицю."),
                    symbol: "tree.fill", kind: .action
                )),
                RoomChoice(Phrase(
                    "home.door.who",
                    Bilingual("Who is it?", uk: "Хто там?"),
                    says: Bilingual("Who is it?", uk: "Хто там?"),
                    symbol: "questionmark.circle.fill", kind: .question
                )),
                RoomChoice(Phrase(
                    "home.door.close",
                    Bilingual("Close the door", uk: "Зачиніть двері"),
                    says: Bilingual("Close the door, please.", uk: "Зачиніть двері, будь ласка."),
                    symbol: "lock.fill", kind: .action
                )),
            ]
        ),
    ]
}
