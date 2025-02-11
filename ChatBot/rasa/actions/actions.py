from typing import Any, Text, Dict, List
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher

class ActionCalcularTalla(Action):
    def name(self) -> Text:
        return "action_calcular_talla"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        altura = tracker.get_slot("altura")
        peso = tracker.get_slot("peso")

        if altura and peso:
            if peso < 60:
                talla = "S"
            elif 60 <= peso <= 80:
                talla = "M"
            elif 80 < peso <= 100:
                talla = "L"
            else:
                talla = "XL"
            
            response = f"Para una altura de {altura} m y un peso de {peso} kg, la talla recomendada es {talla}."
        else:
            response = "Necesito tu altura y peso para recomendarte una talla."

        dispatcher.utter_message(text=response)
        return []
